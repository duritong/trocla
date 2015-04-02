require 'openssl'
require 'base64'

class Trocla::Encryptions::Ssl < Trocla::Encryptions::Base
  def encrypt(value)
    ciphertext = ''
    value.scan(/.{0,#{chunksize}}/m).each do |chunk|
      ciphertext += Base64.encode64(public_key.public_encrypt(chunk)).gsub("\n",'')+"\n" if chunk
    end
    ciphertext
  end

  def decrypt(value)
    plaintext = ''
    value.split(/\n/).each do |line|
      plaintext += private_key.private_decrypt(Base64.decode64(line)) if line
    end
    plaintext
  end

  private

  def chunksize
      public_key.n.num_bytes - 11
  end

  def private_key
      pass = nil
      file = require_option(:private_key)
      @private_key ||= OpenSSL::PKey::RSA.new(File.read(file), nil)
  end

  def public_key
      file = require_option(:public_key)
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
    val = option(key)
    raise "Config error: 'ssl_options' => :#{key} is not defined" if val.nil?
    val
  end
end

