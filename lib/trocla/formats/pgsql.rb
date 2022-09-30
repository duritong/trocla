class Trocla::Formats::Pgsql < Trocla::Formats::Base
  require 'digest/md5'
  require 'openssl'
  require 'base64'
  def format(plain_password, options = {})
    encode = (options['encode'] || 'sha256')
    case encode
    when 'md5'
      raise 'You need pass the username as an option to use this format' unless options['username']

      'md5' + Digest::MD5.hexdigest(plain_password + options['username'])
    when 'sha256'
      pg_sha256(plain_password)
    else
      raise 'Unkmow encode %s for pgsql password' % [encode]
    end
  end

  private

  def pg_sha256(password)
    salt = OpenSSL::Random.random_bytes(16)
    digest = digest_key(password, salt)
    'SCRAM-SHA-256$%s:%s$%s:%s' % [
      '4096',
      Base64.strict_encode64(salt),
      Base64.strict_encode64(client_key(digest)),
      Base64.strict_encode64(server_key(digest))
    ]
  end

  def digest_key(password, salt)
    OpenSSL::KDF.pbkdf2_hmac(
      password,
      salt: salt,
      iterations: 4096,
      length: 32,
      hash: OpenSSL::Digest::SHA256.new
    )
  end

  def client_key(digest_key)
    hmac = OpenSSL::HMAC.new(digest_key, OpenSSL::Digest::SHA256.new)
    hmac << 'Client Key'
    hmac.digest
    OpenSSL::Digest.new('SHA256').digest hmac.digest
  end

  def server_key(digest_key)
    hmac = OpenSSL::HMAC.new(digest_key, OpenSSL::Digest::SHA256.new)
    hmac << 'Server Key'
    hmac.digest
  end
end
