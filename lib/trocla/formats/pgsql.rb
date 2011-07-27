class Trocla::Formats::Pgsql
  require 'digest/md5'
  def format(plain_password,options={})
    raise "You need pass the username in the options for this format" unless options['username'] 
    "md5" + Digest::MD5.hexdigest(plain_password + options['username'])
  end
end