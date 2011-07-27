class Trocla::Formats::Mysql
  require 'digest/sha1'
  def format(plain_password,options={})
    "*" + Digest::SHA1.hexdigest(Digest::SHA1.digest(plain_password)).upcase
  end
end