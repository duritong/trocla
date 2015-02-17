require 'openssl'
require 'base64'

class Trocla::Encryptions::Ssl < Trocla::Encryptions::Base
  def encrypt(value)
    if option :use_base64
      Base64.encode64(public_key.public_encrypt(value))
    else
      public_key.public_encrypt(value)
    end
  end

  def decrypt(value)
    if option :use_base64
      private_key.private_decrypt(Base64.decode64(value))
    else
      private_key.private_decrypt(value)
    end
  end

  private
  def private_key
      pass = nil
      file = require_option :private_key
      @private_key ||= OpenSSL::PKey::RSA.new(File.read(file), nil)
  end

  def public_key
      file = require_option :public_key
      @public_key ||= OpenSSL::PKey::RSA.new(File.read(file), nil)
  end

  def config
    @config = @trocla.config['ssl_options']
    @config ||= Hash.new
  end

  def option(key)
    config[key]
  end

  def require_option(key)
    val = option key
    raise "Config error: 'ssl_options' => :#{key} is not defined" if val.nil?
    val
  end
end

