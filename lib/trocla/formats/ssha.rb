# salted crypt
require 'base64'
require 'digest'
class Trocla::Formats::Ssha < Trocla::Formats::Base
  def format(plain_password, options = {})
    salt = options['salt'] || Trocla::Util.salt(16)
    '{SSHA}' + Base64.encode64("#{Digest::SHA1.digest("#{plain_password}#{salt}")}#{salt}").chomp
  end
end
