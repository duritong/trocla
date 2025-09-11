require 'spec_helper'
require 'trocla/stores/vault_jwt'

describe Trocla::Stores::VaultJwt do
  let(:config) do
    {
      address: 'https://vault.example.com:8200',
      mount: 'kv',
      jwt_auth_path: 'jwt',
      jwt_role: 'trocla-agents',
      trusted_fact: 'certname',
      ca_key_path: '/tmp/test_ca_key.pem',
      ca_cert_path: '/tmp/test_ca_cert.pem',
      token_ttl: 3600,
      cache_tokens: true,
      jwt_claims: {
        iss: 'puppet-ca',
        aud: 'vault',
        sub: '{{trusted_fact}}'
      }
    }
  end

  let(:trocla) { double('trocla') }
  let(:agent_context) do
    {
      trusted_facts: {
        'certname' => 'test-agent.example.com',
        'environment' => 'production'
      },
      environment: 'production',
      timestamp: Time.now.to_i
    }
  end

  let(:mock_vault_client) { double('vault_client') }
  let(:mock_jwt_auth) { double('jwt_auth') }

  before do
    # Mock environment variables for trusted facts
    ENV['PUPPET_TRUSTED_CERTNAME'] = 'test-agent.example.com'
    ENV['PUPPET_TRUSTED_ENVIRONMENT'] = 'production'

    # Mock Trocla logger
    allow(Trocla).to receive(:logger).and_return(double('logger', debug: nil, error: nil, warn: nil))

    # Mock Vault client creation
    allow(Vault::Client).to receive(:new).and_return(mock_vault_client)
    allow(mock_vault_client).to receive(:token=)
    allow(mock_vault_client).to receive(:kv).and_return(double('kv'))

    # Mock JWT authentication
    allow(Trocla::Vault::JwtAuth).to receive(:new).and_return(mock_jwt_auth)
    allow(mock_jwt_auth).to receive(:authenticate).and_return('vault-token-123')
    allow(mock_jwt_auth).to receive(:has_valid_token?).and_return(false)
    allow(mock_jwt_auth).to receive(:stats).and_return({})

    # Mock trusted facts extraction
    allow(Trocla::Util::TrustedFacts).to receive(:extract_agent_context).and_return(agent_context)
    allow(Trocla::Util::TrustedFacts).to receive(:validate_required_facts).and_return(true)
  end

  after do
    # Clean up environment variables
    ENV.delete('PUPPET_TRUSTED_CERTNAME')
    ENV.delete('PUPPET_TRUSTED_ENVIRONMENT')
  end

  describe '#initialize' do
    it 'creates a new vault_jwt store' do
      expect { described_class.new(config, trocla) }.not_to raise_error
    end

    it 'extracts agent context during initialization' do
      expect(Trocla::Util::TrustedFacts).to receive(:extract_agent_context)
      described_class.new(config, trocla)
    end

    it 'initializes JWT authentication' do
      expect(Trocla::Vault::JwtAuth).to receive(:new).with(config)
      described_class.new(config, trocla)
    end

    it 'validates required trusted facts' do
      expect(Trocla::Util::TrustedFacts).to receive(:validate_required_facts)
        .with(['certname'], agent_context)
        .and_return(true)
      described_class.new(config, trocla)
    end

    context 'when required trusted facts are missing' do
      before do
        allow(Trocla::Util::TrustedFacts).to receive(:validate_required_facts).and_return(false)
        allow(ENV).to receive(:[]).with('PUPPET_TRUSTED_CERTNAME').and_return(nil)
      end

      it 'raises an error' do
        expect { described_class.new(config, trocla) }.to raise_error(/Required trusted fact/)
      end
    end

    context 'when fallback environment variable is available' do
      before do
        allow(Trocla::Util::TrustedFacts).to receive(:validate_required_facts).and_return(false)
        allow(ENV).to receive(:[]).with('PUPPET_TRUSTED_CERTNAME').and_return('fallback-agent')
      end

      it 'uses the fallback value' do
        expect { described_class.new(config, trocla) }.not_to raise_error
      end
    end
  end

  describe '#get' do
    let(:store) { described_class.new(config, trocla) }
    let(:mock_kv) { double('kv') }

    before do
      allow(mock_vault_client).to receive(:kv).with('kv').and_return(mock_kv)
      allow(mock_kv).to receive(:read).with('test_key').and_return(
        double('response', data: { plain: 'test_password' })
      )
    end

    it 'ensures authentication before getting value' do
      expect(mock_jwt_auth).to receive(:has_valid_token?).with(agent_context).and_return(false)
      expect(mock_jwt_auth).to receive(:authenticate).with(agent_context).and_return('vault-token-123')
      expect(mock_vault_client).to receive(:token=).with('vault-token-123')

      result = store.get('test_key', 'plain')
      expect(result).to eq('test_password')
    end

    it 'skips authentication if valid token exists' do
      allow(mock_jwt_auth).to receive(:has_valid_token?).with(agent_context).and_return(true)
      expect(mock_jwt_auth).not_to receive(:authenticate)

      result = store.get('test_key', 'plain')
      expect(result).to eq('test_password')
    end
  end

  describe '#authenticated?' do
    let(:store) { described_class.new(config, trocla) }

    it 'returns true when agent has valid token' do
      allow(mock_jwt_auth).to receive(:has_valid_token?).with(agent_context).and_return(true)
      expect(store.authenticated?).to be true
    end

    it 'returns false when agent has no valid token' do
      allow(mock_jwt_auth).to receive(:has_valid_token?).with(agent_context).and_return(false)
      expect(store.authenticated?).to be false
    end
  end

  describe '#refresh_authentication' do
    let(:store) { described_class.new(config, trocla) }

    it 'invalidates current token and re-authenticates' do
      expect(mock_jwt_auth).to receive(:invalidate_token).with(agent_context)
      expect(mock_jwt_auth).to receive(:authenticate).with(agent_context).and_return('new-token-456')
      expect(mock_vault_client).to receive(:token=).with('new-token-456')

      store.refresh_authentication
    end
  end

  describe '#jwt_stats' do
    let(:store) { described_class.new(config, trocla) }
    let(:stats) do
      {
        cache: { total_entries: 1, valid_entries: 1 },
        config: { jwt_role: 'trocla-agents' }
      }
    end

    it 'returns JWT authentication statistics' do
      allow(mock_jwt_auth).to receive(:stats).and_return(stats)
      expect(store.jwt_stats).to eq(stats)
    end
  end

  describe 'write operations' do
    let(:store) { described_class.new(config, trocla) }
    let(:mock_kv) { double('kv') }

    before do
      allow(mock_vault_client).to receive(:kv).with('kv').and_return(mock_kv)
      allow(mock_kv).to receive(:write)
      allow(mock_kv).to receive(:write_metadata)
      allow(mock_kv).to receive(:read).and_return(double('response', data: {}))
    end

    describe '#set' do
      it 'ensures authentication before setting value' do
        expect(mock_jwt_auth).to receive(:has_valid_token?).and_return(false)
        expect(mock_jwt_auth).to receive(:authenticate).and_return('vault-token-123')

        store.set('test_key', 'plain', 'new_password')
      end
    end
  end

  describe 'delete operations' do
    let(:store) { described_class.new(config, trocla) }
    let(:mock_kv) { double('kv') }

    before do
      allow(mock_vault_client).to receive(:kv).with('kv').and_return(mock_kv)
      allow(mock_kv).to receive(:delete)
      allow(mock_kv).to receive(:destroy)
      allow(mock_kv).to receive(:read).and_return(double('response', data: { plain: 'test' }))
      allow(mock_kv).to receive(:write)
    end

    describe '#delete' do
      it 'ensures authentication before deleting value' do
        expect(mock_jwt_auth).to receive(:has_valid_token?).and_return(false)
        expect(mock_jwt_auth).to receive(:authenticate).and_return('vault-token-123')

        store.delete('test_key')
      end
    end
  end

  describe 'error handling' do
    let(:store) { described_class.new(config, trocla) }

    context 'when JWT authentication fails' do
      before do
        allow(mock_jwt_auth).to receive(:authenticate).and_raise('JWT auth failed')
      end

      it 'raises a descriptive error' do
        expect { store.get('test_key', 'plain') }.to raise_error(/Vault JWT authentication failed/)
      end
    end
  end
end