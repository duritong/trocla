# salted crypt
class Trocla::Formats::Sha512crypt < Trocla::Formats::Base
  def format(plain_password,options={})
     plain_password.crypt('$6$' << Trocla::Util.salt << '$')
  end
end
