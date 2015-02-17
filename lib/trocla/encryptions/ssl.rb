require 'openssl'
require 'base64'

class Trocla::Encryptions::Ssl < Trocla::Encryptions::Base
  def encrypt(value)
    if @config[:use_base64]
      Base64.encode64(public_key.public_encrypt(value))
    else
      public_key.public_encrypt(value)
    end
  end

  def decrypt(value)
    if @config[:use_base64]
      private_key.private_decrypt(Base64.decode64(value))
    else
      private_key.private_decrypt(value)
    end
  end

  private
  def private_key
      pass = nil
      file = @trocla.config[:ssl_options][:private_key]
      @private_key ||= OpenSSL::PKey::RSA.new(File.read(file), nil)
  end

  def public_key
      file = @trocla.config[:ssl_options][:public_key]
      @private_key ||= OpenSSL::PKey::RSA.new(File.read(file), nil)
  end
end

