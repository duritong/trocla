require 'spec_helper'
require 'trocla/util/trusted_facts'

describe Trocla::Util::TrustedFacts do
  let(:agent_context) do
    {
      trusted_facts: {
        'certname' => 'test-agent.example.com',
        'environment' => 'production',
        'role' => 'webserver'
      },
      environment: 'production',
      timestamp: Time.now.to_i
    }
  end

  before do
    # Mock Trocla logger
    allow(Trocla).to receive(:logger).and_return(double('logger', debug: nil, error: nil, warn: nil))
  end

  describe '.get_agent_fact' do
    context 'when agent context is provided' do
      it 'returns fact value from trusted_facts hash with string key' do
        result = described_class.get_agent_fact('certname', agent_context)
        expect(result).to eq('test-agent.example.com')
      end

      it 'returns fact value from trusted_facts hash with symbol key' do
        context_with_symbols = {
          trusted_facts: {
            certname: 'test-agent.example.com',
            environment: 'production'
          }
        }
        
        result = described_class.get_agent_fact('certname', context_with_symbols)
        expect(result).to eq('test-agent.example.com')
      end

      it 'returns nil when fact is not found' do
        result = described_class.get_agent_fact('nonexistent', agent_context)
        expect(result).to be_nil
      end
    end

    context 'when agent context is not provided' do
      before do
        ENV['PUPPET_TRUSTED_CERTNAME'] = 'env-agent.example.com'
      end

      after do
        ENV.delete('PUPPET_TRUSTED_CERTNAME')
      end

      it 'falls back to environment variables' do
        result = described_class.get_agent_fact('certname')
        expect(result).to eq('env-agent.example.com')
      end
    end

    context 'when Puppet is available' do
      let(:mock_trusted_info) do
        {
          'certname' => 'puppet-agent.example.com',
          'environment' => 'staging'
        }
      end

      before do
        # Mock Puppet availability and trusted information
        stub_const('Puppet', double('Puppet'))
        allow(Puppet).to receive(:respond_to?).with(:lookup).and_return(true)
        allow(Puppet).to receive(:lookup).with(:trusted_information).and_return(mock_trusted_info)
      end

      it 'gets fact from Puppet trusted information' do
        result = described_class.get_agent_fact('certname')
        expect(result).to eq('puppet-agent.example.com')
      end

      it 'handles symbol keys in Puppet trusted information' do
        trusted_info_with_symbols = {
          certname: 'puppet-agent.example.com'
        }
        allow(Puppet).to receive(:lookup).with(:trusted_information).and_return(trusted_info_with_symbols)
        
        result = described_class.get_agent_fact('certname')
        expect(result).to eq('puppet-agent.example.com')
      end
    end

    context 'when Puppet compiler context is available' do
      before do
        stub_const('Puppet', double('Puppet'))
        stub_const('Puppet::Parser::Compiler', double('Compiler'))
        
        allow(Puppet).to receive(:respond_to?).with(:[]).and_return(true)
        allow(Puppet).to receive(:[]).with(:trusted_node_data).and_return(true)
        allow(Puppet::Parser::Compiler).to receive(:current_node_name).and_return('compiler-agent.example.com')
      end

      it 'gets certname from Puppet compiler context' do
        result = described_class.get_agent_fact('certname')
        expect(result).to eq('compiler-agent.example.com')
      end
    end
  end

  describe '.get_agent_facts' do
    it 'returns hash of multiple facts' do
      fact_names = ['certname', 'environment', 'role']
      result = described_class.get_agent_facts(fact_names, agent_context)
      
      expect(result).to eq({
        'certname' => 'test-agent.example.com',
        'environment' => 'production',
        'role' => 'webserver'
      })
    end

    it 'includes nil values for missing facts' do
      fact_names = ['certname', 'nonexistent']
      result = described_class.get_agent_facts(fact_names, agent_context)
      
      expect(result).to eq({
        'certname' => 'test-agent.example.com',
        'nonexistent' => nil
      })
    end
  end

  describe '.extract_agent_context' do
    context 'when Puppet is not available' do
      before do
        ENV['PUPPET_TRUSTED_CERTNAME'] = 'env-agent.example.com'
        ENV['PUPPET_TRUSTED_ENVIRONMENT'] = 'development'
      end

      after do
        ENV.delete('PUPPET_TRUSTED_CERTNAME')
        ENV.delete('PUPPET_TRUSTED_ENVIRONMENT')
      end

      it 'extracts context from environment variables' do
        result = described_class.extract_agent_context
        
        expect(result[:trusted_facts]['certname']).to eq('env-agent.example.com')
        expect(result[:trusted_facts]['environment']).to eq('development')
        expect(result[:timestamp]).to be_a(Integer)
      end
    end

    context 'when Puppet is available' do
      let(:mock_trusted_info) do
        double('trusted_info', to_h: {
          'certname' => 'puppet-agent.example.com',
          'environment' => 'production'
        })
      end

      before do
        stub_const('Puppet', double('Puppet'))
        allow(Puppet).to receive(:respond_to?).with(:lookup).and_return(true)
        allow(Puppet).to receive(:respond_to?).with(:[]).and_return(true)
        allow(Puppet).to receive(:lookup).with(:trusted_information).and_return(mock_trusted_info)
        allow(Puppet).to receive(:[]).with(:environment).and_return('production')
      end

      it 'extracts context from Puppet' do
        result = described_class.extract_agent_context
        
        expect(result[:trusted_facts]['certname']).to eq('puppet-agent.example.com')
        expect(result[:environment]).to eq('production')
        expect(result[:timestamp]).to be_a(Integer)
      end
    end

    context 'when Puppet compiler is available' do
      before do
        stub_const('Puppet', double('Puppet'))
        stub_const('Puppet::Parser::Compiler', double('Compiler'))
        
        allow(Puppet).to receive(:respond_to?).with(:lookup).and_return(true)
        allow(Puppet).to receive(:lookup).with(:trusted_information).and_return(nil)
        allow(Puppet::Parser::Compiler).to receive(:respond_to?).with(:current_node_name).and_return(true)
        allow(Puppet::Parser::Compiler).to receive(:current_node_name).and_return('compiler-node')
      end

      it 'gets node name from compiler' do
        result = described_class.extract_agent_context
        expect(result[:trusted_facts]['certname']).to eq('compiler-node')
      end
    end

    it 'handles Puppet errors gracefully' do
      stub_const('Puppet', double('Puppet'))
      allow(Puppet).to receive(:respond_to?).and_raise(StandardError.new('Puppet error'))
      
      expect { described_class.extract_agent_context }.not_to raise_error
    end
  end

  describe '.validate_required_facts' do
    it 'returns true when all required facts are present' do
      required_facts = ['certname', 'environment']
      result = described_class.validate_required_facts(required_facts, agent_context)
      expect(result).to be true
    end

    it 'returns false when required facts are missing' do
      required_facts = ['certname', 'nonexistent']
      result = described_class.validate_required_facts(required_facts, agent_context)
      expect(result).to be false
    end

    it 'returns false when required facts are empty strings' do
      context_with_empty = {
        trusted_facts: {
          'certname' => '',
          'environment' => 'production'
        }
      }
      
      required_facts = ['certname']
      result = described_class.validate_required_facts(required_facts, context_with_empty)
      expect(result).to be false
    end

    it 'returns false when required facts are nil' do
      context_with_nil = {
        trusted_facts: {
          'certname' => nil,
          'environment' => 'production'
        }
      }
      
      required_facts = ['certname']
      result = described_class.validate_required_facts(required_facts, context_with_nil)
      expect(result).to be false
    end

    it 'returns false when required facts are whitespace only' do
      context_with_whitespace = {
        trusted_facts: {
          'certname' => '   ',
          'environment' => 'production'
        }
      }
      
      required_facts = ['certname']
      result = described_class.validate_required_facts(required_facts, context_with_whitespace)
      expect(result).to be false
    end

    context 'when no agent context is provided' do
      before do
        ENV['PUPPET_TRUSTED_CERTNAME'] = 'env-agent.example.com'
      end

      after do
        ENV.delete('PUPPET_TRUSTED_CERTNAME')
      end

      it 'validates facts from environment variables' do
        required_facts = ['certname']
        result = described_class.validate_required_facts(required_facts)
        expect(result).to be true
      end
    end
  end
end