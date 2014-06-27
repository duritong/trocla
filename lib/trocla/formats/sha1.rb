class Trocla::Formats::Sha1
  require 'digest/sha1'
  require 'base64'
  def format(plain_password,options={})
    '{SHA}' + Base64.encode64(Digest::SHA1.digest(plain_password))
  end
end
