require_relative 'vault'
require_relative '../vault/jwt_auth'
require_relative '../util/trusted_facts'

# Vault store with JWT authentication support
class Trocla
  module Stores
    class VaultJwt < Trocla::Stores::Vault
  attr_reader :jwt_auth, :agent_context

  def initialize(config, trocla)
    # Extract agent context before calling super
    @agent_context = extract_agent_context
    
    # Initialize JWT authentication
    @jwt_auth = Trocla::Vault::JwtAuth.new(config)
    
    # Remove JWT-specific config before passing to parent
    vault_config = prepare_vault_config(config)
    
    # Call parent constructor with cleaned config
    super(vault_config, trocla)
    
    # Override the vault client with JWT-authenticated one
    setup_jwt_authenticated_client
  end

  # Override get method to ensure JWT authentication
  def get(key, format)
    ensure_authenticated_for_current_agent
    super(key, format)
  end

  # Override formats method to ensure JWT authentication
  def formats(key)
    ensure_authenticated_for_current_agent
    super(key)
  end

  # Override search method to ensure JWT authentication
  def search(key)
    ensure_authenticated_for_current_agent
    super(key)
  end

  # Get JWT authentication statistics
  def jwt_stats
    @jwt_auth.stats
  end

  # Refresh JWT authentication for current agent
  def refresh_authentication
    @jwt_auth.invalidate_token(@agent_context)
    setup_jwt_authenticated_client
  end

  # Check if current agent has valid authentication
  def authenticated?
    @jwt_auth.has_valid_token?(@agent_context)
  end

  private

  # Override parent's write methods to ensure authentication
  def write(key, value, options = {})
    ensure_authenticated_for_current_agent
    super(key, value, options)
  end

  def set_plain(key, value, options)
    ensure_authenticated_for_current_agent
    super(key, value, options)
  end

  def set_format(key, format, value, options)
    ensure_authenticated_for_current_agent
    super(key, format, value, options)
  end

  def delete_all(key)
    ensure_authenticated_for_current_agent
    super(key)
  end

  def delete_format(key, format)
    ensure_authenticated_for_current_agent
    super(key, format)
  end

  # Ensure the current agent is authenticated with Vault
  def ensure_authenticated_for_current_agent
    return if @jwt_auth.has_valid_token?(@agent_context)
    
    setup_jwt_authenticated_client
  end

  # Setup Vault client with JWT authentication
  def setup_jwt_authenticated_client
    begin
      # Get JWT token for current agent
      jwt_token = @jwt_auth.authenticate(@agent_context)
      
      # Update vault client token
      @vault.token = jwt_token
      
      log_debug("Successfully authenticated agent #{get_agent_id} with Vault")
    rescue => e
      log_error("Failed to authenticate agent #{get_agent_id} with Vault: #{e.message}")
      raise "Vault JWT authentication failed: #{e.message}"
    end
  end

  # Extract agent context from current Puppet compilation
  def extract_agent_context
    context = Trocla::Util::TrustedFacts.extract_agent_context
    
    # Validate that we have the required trusted facts
    trusted_fact_name = @store_config[:trusted_fact] || 'certname'
    unless Trocla::Util::TrustedFacts.validate_required_facts([trusted_fact_name], context)
      log_error("Required trusted fact '#{trusted_fact_name}' not available in agent context")
      # Try to get from environment as fallback
      fallback_value = ENV["PUPPET_TRUSTED_#{trusted_fact_name.upcase}"]
      if fallback_value
        context[:trusted_facts][trusted_fact_name] = fallback_value
        log_debug("Using fallback value for trusted fact '#{trusted_fact_name}' from environment")
      else
        raise "Required trusted fact '#{trusted_fact_name}' not available"
      end
    end
    
    log_debug("Extracted agent context for #{get_agent_id(context)}")
    context
  end

  # Prepare Vault configuration by removing JWT-specific options
  def prepare_vault_config(config)
    vault_config = config.dup
    
    # Remove JWT-specific configuration keys
    jwt_keys = [
      :jwt_auth_path, :jwt_role, :trusted_fact, :ca_key_path, :ca_cert_path,
      :jwt_claims, :token_ttl, :cache_tokens, :jwt_algorithm, :jwt_issuer, :jwt_audience
    ]
    
    jwt_keys.each { |key| vault_config.delete(key) }
    
    vault_config
  end

  # Get agent ID from context
  def get_agent_id(context = nil)
    context ||= @agent_context
    trusted_fact_name = @store_config[:trusted_fact] || 'certname'
    Trocla::Util::TrustedFacts.get_agent_fact(trusted_fact_name, context) || 'unknown'
  end

  # Log error message
  def log_error(message)
    if defined?(Trocla) && Trocla.respond_to?(:logger)
      Trocla.logger.error("[VaultJWT] #{message}")
    else
      warn("[VaultJWT] #{message}")
    end
  end

  # Log debug message
  def log_debug(message)
    if defined?(Trocla) && Trocla.respond_to?(:logger)
      Trocla.logger.debug("[VaultJWT] #{message}")
    end
  end
    end
  end
end