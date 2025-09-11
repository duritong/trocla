# Utility module for reading Puppet trusted facts
class Trocla
  module Util
    module TrustedFacts
  class << self
    # Get a trusted fact value for the current agent context
    # @param fact_name [String] The name of the trusted fact to retrieve
    # @param agent_context [Hash] The agent context containing trusted facts
    # @return [String, nil] The fact value or nil if not found
    def get_agent_fact(fact_name, agent_context = nil)
      # Try to get from provided context first
      if agent_context && agent_context[:trusted_facts]
        return agent_context[:trusted_facts][fact_name.to_s] || agent_context[:trusted_facts][fact_name.to_sym]
      end

      # Try to get from Puppet's trusted facts if available
      if defined?(Puppet) && Puppet.respond_to?(:lookup) && Puppet.lookup(:trusted_information)
        trusted_info = Puppet.lookup(:trusted_information)
        if trusted_info && trusted_info.respond_to?(:[])
          return trusted_info[fact_name.to_s] || trusted_info[fact_name.to_sym]
        end
      end

      # Try to get from Puppet's global scope if available
      if defined?(Puppet) && Puppet.respond_to?(:[]) && Puppet[:trusted_node_data]
        begin
          # Access trusted facts from Puppet's current compilation context
          if Puppet::Parser::Compiler.current_node_name
            node_name = Puppet::Parser::Compiler.current_node_name
            return node_name if fact_name.to_s == 'certname'
          end
        rescue => e
          Trocla.logger.debug("Could not access Puppet compiler context: #{e.message}")
        end
      end

      # Fallback: try environment variables
      env_var = "PUPPET_TRUSTED_#{fact_name.upcase}"
      ENV[env_var]
    end

    # Get multiple trusted facts at once
    # @param fact_names [Array<String>] Array of fact names to retrieve
    # @param agent_context [Hash] The agent context containing trusted facts
    # @return [Hash] Hash of fact_name => value pairs
    def get_agent_facts(fact_names, agent_context = nil)
      facts = {}
      fact_names.each do |fact_name|
        facts[fact_name] = get_agent_fact(fact_name, agent_context)
      end
      facts
    end

    # Extract agent context from current Puppet compilation
    # @return [Hash] Agent context with trusted facts and environment info
    def extract_agent_context
      context = {
        trusted_facts: {},
        environment: nil,
        timestamp: Time.now.to_i
      }

      # Try to get trusted facts from Puppet
      if defined?(Puppet)
        begin
          # Get trusted information if available
          if Puppet.respond_to?(:lookup)
            trusted_info = Puppet.lookup(:trusted_information)
            if trusted_info
              context[:trusted_facts] = trusted_info.to_h if trusted_info.respond_to?(:to_h)
            end
          end

          # Get environment information
          if Puppet.respond_to?(:[]) && Puppet[:environment]
            context[:environment] = Puppet[:environment].to_s
          end

          # Try to get node name from compiler
          if defined?(Puppet::Parser::Compiler) && Puppet::Parser::Compiler.respond_to?(:current_node_name)
            node_name = Puppet::Parser::Compiler.current_node_name
            context[:trusted_facts]['certname'] = node_name if node_name
              end
            end
          end
        rescue => e
          Trocla.logger.debug("Could not extract full agent context: #{e.message}")
        end
      end

      # Fallback to environment variables
      if context[:trusted_facts].empty?
        ENV.each do |key, value|
          if key.start_with?('PUPPET_TRUSTED_')
            fact_name = key.sub('PUPPET_TRUSTED_', '').downcase
            context[:trusted_facts][fact_name] = value
          end
        end
      end

      context
    end

    # Validate that required trusted facts are available
    # @param required_facts [Array<String>] Array of required fact names
    # @param agent_context [Hash] The agent context to validate
    # @return [Boolean] True if all required facts are present
    def validate_required_facts(required_facts, agent_context = nil)
      required_facts.all? do |fact_name|
        value = get_agent_fact(fact_name, agent_context)
        !value.nil? && !value.to_s.strip.empty?
      end
    end
  end
end