require 'jwt'
require 'openssl'

# Utility module for generating JWT tokens signed by Puppet CA
class Trocla
  module Util
    module JwtGenerator
  class << self
    # Generate a JWT token with the given claims, signed by Puppet CA
    # @param claims [Hash] The claims to include in the JWT
    # @param ca_key_path [String] Path to the Puppet CA private key
    # @param algorithm [String] JWT signing algorithm (default: RS256)
    # @return [String] The signed JWT token
    def generate(claims, ca_key_path, algorithm = 'RS256')
      # Load the CA private key
      ca_key = load_ca_key(ca_key_path)
      
      # Set default claims
      now = Time.now.to_i
      default_claims = {
        iat: now,                    # Issued at
        nbf: now,                    # Not before
        exp: now + 3600,             # Expires in 1 hour
        jti: SecureRandom.uuid       # JWT ID for uniqueness
      }
      
      # Merge with provided claims
      final_claims = default_claims.merge(claims)
      
      # Generate and return the JWT
      JWT.encode(final_claims, ca_key, algorithm)
    rescue => e
      raise "Failed to generate JWT: #{e.message}"
    end

    # Generate JWT claims from agent context and configuration
    # @param agent_context [Hash] The agent context with trusted facts
    # @param config [Hash] JWT configuration with claims template
    # @return [Hash] The processed claims ready for JWT generation
    def generate_claims(agent_context, config)
      claims = {}
      
      # Process configured claims
      if config[:jwt_claims]
        config[:jwt_claims].each do |claim_key, claim_value|
          claims[claim_key.to_sym] = process_claim_value(claim_value, agent_context, config)
        end
      end
      
      # Ensure required claims are present
      ensure_required_claims(claims, agent_context, config)
      
      claims
    end

    # Generate a complete JWT for an agent
    # @param agent_context [Hash] The agent context with trusted facts
    # @param config [Hash] JWT configuration
    # @return [String] The signed JWT token
    def generate_for_agent(agent_context, config)
      claims = generate_claims(agent_context, config)
      ca_key_path = config[:ca_key_path] || '/etc/puppetlabs/puppet/ssl/private_keys/ca.pem'
      algorithm = config[:jwt_algorithm] || 'RS256'
      
      generate(claims, ca_key_path, algorithm)
    end

    private

    # Load the Puppet CA private key
    # @param ca_key_path [String] Path to the CA private key file
    # @return [OpenSSL::PKey] The loaded private key
    def load_ca_key(ca_key_path)
      unless File.exist?(ca_key_path)
        raise "CA private key not found at: #{ca_key_path}"
      end
      
      key_content = File.read(ca_key_path)
      
      # Try to load as RSA key first, then as generic PKey
      begin
        OpenSSL::PKey::RSA.new(key_content)
      rescue OpenSSL::PKey::RSAError
        begin
          OpenSSL::PKey.read(key_content)
        rescue => e
          raise "Failed to load CA private key: #{e.message}"
        end
      end
    end

    # Process a claim value, replacing placeholders with actual values
    # @param claim_value [String, Object] The claim value template
    # @param agent_context [Hash] The agent context
    # @param config [Hash] The configuration
    # @return [Object] The processed claim value
    def process_claim_value(claim_value, agent_context, config)
      return claim_value unless claim_value.is_a?(String)
      
      processed_value = claim_value.dup
      
      # Replace trusted fact placeholders
      processed_value.gsub!(/\{\{trusted_fact\}\}/) do
        trusted_fact_name = config[:trusted_fact] || 'certname'
        Trocla::Util::TrustedFacts.get_agent_fact(trusted_fact_name, agent_context) || 'unknown'
      end
      
      # Replace specific trusted fact placeholders
      processed_value.gsub!(/\{\{([^}]+)\}\}/) do |match|
        fact_name = $1
        case fact_name
        when 'environment'
          agent_context[:environment] || 'production'
        when 'timestamp'
          agent_context[:timestamp] || Time.now.to_i
        else
          # Try to get as trusted fact
          Trocla::Util::TrustedFacts.get_agent_fact(fact_name, agent_context) || match
            end
          end
        end
      end
      
      processed_value
    end

    # Ensure required claims are present in the claims hash
    # @param claims [Hash] The claims hash to modify
    # @param agent_context [Hash] The agent context
    # @param config [Hash] The configuration
    def ensure_required_claims(claims, agent_context, config)
      # Ensure issuer is set
      claims[:iss] ||= config[:jwt_issuer] || 'puppet-ca'
      
      # Ensure audience is set
      claims[:aud] ||= config[:jwt_audience] || 'vault'
      
      # Ensure subject is set (usually the agent identity)
      unless claims[:sub]
        trusted_fact_name = config[:trusted_fact] || 'certname'
        subject = Trocla::Util::TrustedFacts.get_agent_fact(trusted_fact_name, agent_context)
        claims[:sub] = subject || 'unknown-agent'
      end
      
      # Add custom TTL if configured
      if config[:token_ttl]
        claims[:exp] = Time.now.to_i + config[:token_ttl].to_i
      end
    end
  end
end