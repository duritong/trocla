require 'spec_helper'
require 'trocla/util/jwt_generator'
require 'jwt'
require 'openssl'

describe Trocla::Util::JwtGenerator do
  let(:test_key_path) { '/tmp/test_ca_key.pem' }
  let(:test_rsa_key) { OpenSSL::PKey::RSA.new(2048) }
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
  let(:config) do
    {
      trusted_fact: 'certname',
      ca_key_path: test_key_path,
      jwt_claims: {
        iss: 'puppet-ca',
        aud: 'vault',
        sub: '{{trusted_fact}}'
      },
      token_ttl: 3600
    }
  end

  before do
    # Create a temporary RSA key file for testing
    File.write(test_key_path, test_rsa_key.to_pem)
  end

  after do
    # Clean up temporary key file
    File.delete(test_key_path) if File.exist?(test_key_path)
  end

  describe '.generate' do
    let(:claims) do
      {
        iss: 'puppet-ca',
        aud: 'vault',
        sub: 'test-agent.example.com',
        iat: Time.now.to_i,
        exp: Time.now.to_i + 3600
      }
    end

    it 'generates a valid JWT token' do
      token = described_class.generate(claims, test_key_path)
      expect(token).to be_a(String)
      expect(token.split('.').length).to eq(3) # JWT has 3 parts
    end

    it 'signs the token with the provided key' do
      token = described_class.generate(claims, test_key_path)
      
      # Verify the token can be decoded with the public key
      decoded = JWT.decode(token, test_rsa_key.public_key, true, { algorithm: 'RS256' })
      expect(decoded[0]['iss']).to eq('puppet-ca')
      expect(decoded[0]['sub']).to eq('test-agent.example.com')
    end

    it 'includes default claims' do
      token = described_class.generate({}, test_key_path)
      decoded = JWT.decode(token, test_rsa_key.public_key, true, { algorithm: 'RS256' })
      
      expect(decoded[0]).to have_key('iat')
      expect(decoded[0]).to have_key('nbf')
      expect(decoded[0]).to have_key('exp')
      expect(decoded[0]).to have_key('jti')
    end

    it 'merges provided claims with defaults' do
      custom_claims = { custom_field: 'custom_value' }
      token = described_class.generate(custom_claims, test_key_path)
      decoded = JWT.decode(token, test_rsa_key.public_key, true, { algorithm: 'RS256' })
      
      expect(decoded[0]['custom_field']).to eq('custom_value')
      expect(decoded[0]).to have_key('iat') # Default claim still present
    end

    context 'when key file does not exist' do
      it 'raises an error' do
        expect {
          described_class.generate(claims, '/nonexistent/key.pem')
        }.to raise_error(/CA private key not found/)
      end
    end

    context 'when key file is invalid' do
      let(:invalid_key_path) { '/tmp/invalid_key.pem' }

      before do
        File.write(invalid_key_path, 'invalid key content')
      end

      after do
        File.delete(invalid_key_path) if File.exist?(invalid_key_path)
      end

      it 'raises an error' do
        expect {
          described_class.generate(claims, invalid_key_path)
        }.to raise_error(/Failed to load CA private key/)
      end
    end
  end

  describe '.generate_claims' do
    it 'processes configured claims' do
      claims = described_class.generate_claims(agent_context, config)
      
      expect(claims[:iss]).to eq('puppet-ca')
      expect(claims[:aud]).to eq('vault')
      expect(claims[:sub]).to eq('test-agent.example.com')
    end

    it 'replaces trusted_fact placeholder' do
      config_with_placeholder = config.merge(
        jwt_claims: { sub: '{{trusted_fact}}' }
      )
      
      claims = described_class.generate_claims(agent_context, config_with_placeholder)
      expect(claims[:sub]).to eq('test-agent.example.com')
    end

    it 'replaces environment placeholder' do
      config_with_env = config.merge(
        jwt_claims: { env: '{{environment}}' }
      )
      
      claims = described_class.generate_claims(agent_context, config_with_env)
      expect(claims[:env]).to eq('production')
    end

    it 'replaces specific trusted fact placeholders' do
      config_with_certname = config.merge(
        jwt_claims: { certname: '{{certname}}' }
      )
      
      allow(Trocla::Util::TrustedFacts).to receive(:get_agent_fact)
        .with('certname', agent_context)
        .and_return('test-agent.example.com')
      
      claims = described_class.generate_claims(agent_context, config_with_certname)
      expect(claims[:certname]).to eq('test-agent.example.com')
    end

    it 'ensures required claims are present' do
      minimal_config = { trusted_fact: 'certname' }
      
      allow(Trocla::Util::TrustedFacts).to receive(:get_agent_fact)
        .with('certname', agent_context)
        .and_return('test-agent.example.com')
      
      claims = described_class.generate_claims(agent_context, minimal_config)
      
      expect(claims[:iss]).to eq('puppet-ca')
      expect(claims[:aud]).to eq('vault')
      expect(claims[:sub]).to eq('test-agent.example.com')
    end

    it 'applies custom TTL when configured' do
      config_with_ttl = config.merge(token_ttl: 7200)
      
      allow(Time).to receive(:now).and_return(Time.at(1000))
      
      claims = described_class.generate_claims(agent_context, config_with_ttl)
      expect(claims[:exp]).to eq(1000 + 7200)
    end
  end

  describe '.generate_for_agent' do
    before do
      allow(Trocla::Util::TrustedFacts).to receive(:get_agent_fact)
        .with('certname', agent_context)
        .and_return('test-agent.example.com')
    end

    it 'generates a complete JWT for an agent' do
      token = described_class.generate_for_agent(agent_context, config)
      expect(token).to be_a(String)
      
      decoded = JWT.decode(token, test_rsa_key.public_key, true, { algorithm: 'RS256' })
      expect(decoded[0]['sub']).to eq('test-agent.example.com')
    end

    it 'uses default algorithm when not specified' do
      token = described_class.generate_for_agent(agent_context, config)
      
      # Should be decodable with RS256
      expect {
        JWT.decode(token, test_rsa_key.public_key, true, { algorithm: 'RS256' })
      }.not_to raise_error
    end

    it 'uses custom algorithm when specified' do
      config_with_algo = config.merge(jwt_algorithm: 'RS256')
      token = described_class.generate_for_agent(agent_context, config_with_algo)
      
      expect {
        JWT.decode(token, test_rsa_key.public_key, true, { algorithm: 'RS256' })
      }.not_to raise_error
    end

    it 'uses default CA key path when not specified' do
      config_without_key = config.dup
      config_without_key.delete(:ca_key_path)
      
      # Mock the default path
      default_path = '/etc/puppetlabs/puppet/ssl/private_keys/ca.pem'
      allow(File).to receive(:exist?).with(default_path).and_return(true)
      allow(File).to receive(:read).with(default_path).and_return(test_rsa_key.to_pem)
      
      expect {
        described_class.generate_for_agent(agent_context, config_without_key)
      }.not_to raise_error
    end
  end
end