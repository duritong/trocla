require 'thread'

# Thread-safe token cache for Vault tokens per agent
class Trocla
  module Vault
    class TokenCache
  def initialize
    @cache = {}
    @mutex = Mutex.new
    @cleanup_thread = nil
    start_cleanup_thread
  end

  # Get a cached token for an agent
  # @param agent_id [String] The agent identifier
  # @return [String, nil] The cached token or nil if not found/expired
  def get_token(agent_id)
    @mutex.synchronize do
      entry = @cache[agent_id]
      return nil unless entry
      
      # Check if token is expired
      if entry[:expires_at] <= Time.now
        @cache.delete(agent_id)
        return nil
      end
      
      entry[:token]
    end
  end

  # Set a token in the cache for an agent
  # @param agent_id [String] The agent identifier
  # @param token [String] The Vault token
  # @param ttl [Integer] Time to live in seconds
  def set_token(agent_id, token, ttl)
    expires_at = Time.now + ttl
    
    @mutex.synchronize do
      @cache[agent_id] = {
        token: token,
        expires_at: expires_at,
        created_at: Time.now
      }
    end
    
    token
  end

  # Invalidate a token for an agent
  # @param agent_id [String] The agent identifier
  def invalidate_token(agent_id)
    @mutex.synchronize do
      @cache.delete(agent_id)
    end
  end

  # Clear all cached tokens
  def clear_all
    @mutex.synchronize do
      @cache.clear
    end
  end

  # Get cache statistics
  # @return [Hash] Cache statistics
  def stats
    @mutex.synchronize do
      now = Time.now
      total_entries = @cache.size
      expired_entries = @cache.count { |_, entry| entry[:expires_at] <= now }
      valid_entries = total_entries - expired_entries
      
      {
        total_entries: total_entries,
        valid_entries: valid_entries,
        expired_entries: expired_entries,
        agents: @cache.keys
      }
    end
  end

  # Check if a token exists and is valid for an agent
  # @param agent_id [String] The agent identifier
  # @return [Boolean] True if token exists and is valid
  def has_valid_token?(agent_id)
    !get_token(agent_id).nil?
  end

  # Get the expiration time for an agent's token
  # @param agent_id [String] The agent identifier
  # @return [Time, nil] The expiration time or nil if no token
  def token_expires_at(agent_id)
    @mutex.synchronize do
      entry = @cache[agent_id]
      entry ? entry[:expires_at] : nil
    end
  end

  # Get the remaining TTL for an agent's token
  # @param agent_id [String] The agent identifier
  # @return [Integer, nil] Remaining seconds or nil if no token
  def token_ttl(agent_id)
    expires_at = token_expires_at(agent_id)
    return nil unless expires_at
    
    remaining = expires_at - Time.now
    remaining > 0 ? remaining.to_i : 0
  end

  # Cleanup expired tokens
  def cleanup_expired
    @mutex.synchronize do
      now = Time.now
      @cache.delete_if { |_, entry| entry[:expires_at] <= now }
        end
      end
    end
  end

  # Stop the cleanup thread
  def stop_cleanup_thread
    if @cleanup_thread
      @cleanup_thread.kill
      @cleanup_thread = nil
    end
  end

  private

  # Start a background thread to periodically clean up expired tokens
  def start_cleanup_thread
    return if @cleanup_thread&.alive?
    
    @cleanup_thread = Thread.new do
      loop do
        begin
          sleep(300) # Clean up every 5 minutes
          cleanup_expired
        rescue => e
          # Log error but continue running
          if defined?(Trocla) && Trocla.respond_to?(:logger)
            Trocla.logger.warn("Token cache cleanup error: #{e.message}")
          end
        end
      end
    end
    
    # Set thread as daemon so it doesn't prevent process exit
    @cleanup_thread.daemon = true
  end
end