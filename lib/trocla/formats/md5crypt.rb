# salted crypt
class Trocla::Formats::Md5crypt < Trocla::Formats::Base
  def format(plain_password,options={})
     plain_password.crypt('$1$' << Trocla::Util.salt << '$')
  end
end
