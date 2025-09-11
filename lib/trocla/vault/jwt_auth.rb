require_relative 'token_cache'
require_relative '../util/trusted_facts'
require_relative '../util/jwt_generator'

# JWT authentication handler for Vault
class Trocla
  module Vault
    class JwtAuth
  attr_reader :config, :token_cache

  def initialize(config)
    @config = config
    @token_cache = Trocla::Vault::TokenCache.new
  end

  # Authenticate an agent and return a Vault token
  # @param agent_context [Hash] The agent context with trusted facts
  # @return [String] The Vault authentication token
  def authenticate(agent_context)
    agent_id = get_agent_id(agent_context)
    
    # Check if we have a valid cached token
    cached_token = @token_cache.get_token(agent_id)
    return cached_token if cached_token
    
    # Generate new JWT and authenticate with Vault
    jwt_token = generate_jwt_for_agent(agent_context)
    vault_token = authenticate_with_vault(jwt_token)
    
    # Cache the token
    ttl = extract_token_ttl(vault_token) || @config[:token_ttl] || 3600
    @token_cache.set_token(agent_id, vault_token[:client_token], ttl)
    
    vault_token[:client_token]
  rescue => e
    log_error("Authentication failed for agent #{agent_id}: #{e.message}")
    raise "Vault JWT authentication failed: #{e.message}"
  end

  # Check if an agent has a valid cached token
  # @param agent_context [Hash] The agent context
  # @return [Boolean] True if agent has valid cached token
  def has_valid_token?(agent_context)
    agent_id = get_agent_id(agent_context)
    @token_cache.has_valid_token?(agent_id)
  end

  # Invalidate cached token for an agent
  # @param agent_context [Hash] The agent context
  def invalidate_token(agent_context)
    agent_id = get_agent_id(agent_context)
    @token_cache.invalidate_token(agent_id)
  end

  # Get authentication statistics
  # @return [Hash] Authentication and cache statistics
  def stats
    {
      cache: @token_cache.stats,
      config: {
        jwt_auth_path: @config[:jwt_auth_path],
        jwt_role: @config[:jwt_role],
        trusted_fact: @config[:trusted_fact],
        cache_enabled: @config[:cache_tokens] != false
      }
    }
  end

  private

  # Get a unique identifier for an agent
  # @param agent_context [Hash] The agent context
  # @return [String] The agent identifier
  def get_agent_id(agent_context)
    trusted_fact_name = @config[:trusted_fact] || 'certname'
    agent_id = Trocla::Util::TrustedFacts.get_agent_fact(trusted_fact_name, agent_context)
    
    if agent_id.nil? || agent_id.strip.empty?
      raise "Could not determine agent ID from trusted fact '#{trusted_fact_name}'"
    end
    
    agent_id.to_s
  end

  # Generate JWT token for an agent
  # @param agent_context [Hash] The agent context
  # @return [String] The JWT token
  def generate_jwt_for_agent(agent_context)
    # Validate required trusted facts
    required_facts = [@config[:trusted_fact] || 'certname']
    unless Trocla::Util::TrustedFacts.validate_required_facts(required_facts, agent_context)
      raise "Required trusted facts not available: #{required_facts.join(', ')}"
    end
    
    Trocla::Util::JwtGenerator.generate_for_agent(agent_context, @config)
  end

  # Authenticate with Vault using JWT
  # @param jwt_token [String] The JWT token
  # @return [Hash] The Vault authentication response
  def authenticate_with_vault(jwt_token)
    vault_client = create_vault_client
    auth_path = @config[:jwt_auth_path] || 'jwt'
    role = @config[:jwt_role] || 'trocla-agents'
    
    # Perform JWT authentication
    response = vault_client.auth.jwt(
      jwt: jwt_token,
      role: role,
      path: auth_path
    )
    
    unless response && response[:client_token]
      raise "Invalid response from Vault JWT auth"
    end
    
    response
  rescue => e
    raise "Vault JWT authentication request failed: #{e.message}"
  end

  # Create a Vault client for authentication
  # @return [Vault::Client] The Vault client
  def create_vault_client
    require 'vault'
    
    # Create client with basic configuration (no token needed for auth)
    client_config = @config.dup
    client_config.delete(:jwt_auth_path)
    client_config.delete(:jwt_role)
    client_config.delete(:trusted_fact)
    client_config.delete(:ca_key_path)
    client_config.delete(:ca_cert_path)
    client_config.delete(:jwt_claims)
    client_config.delete(:token_ttl)
    client_config.delete(:cache_tokens)
    
    Vault::Client.new(client_config)
      end
    end
  end

  # Extract TTL from Vault token response
  # @param token_response [Hash] The Vault token response
  # @return [Integer, nil] The TTL in seconds
  def extract_token_ttl(token_response)
    return nil unless token_response
    
    # Try different possible TTL fields
    ttl = token_response[:lease_duration] || 
          token_response[:ttl] || 
          token_response.dig(:auth, :lease_duration) ||
          token_response.dig(:auth, :ttl)
    
    ttl&.to_i
  end

  # Log error message
  # @param message [String] The error message
  def log_error(message)
    if defined?(Trocla) && Trocla.respond_to?(:logger)
      Trocla.logger.error(message)
    else
      warn(message)
    end
  end

  # Log debug message
  # @param message [String] The debug message
  def log_debug(message)
    if defined?(Trocla) && Trocla.respond_to?(:logger)
      Trocla.logger.debug(message)
    end
  end
end