# salted crypt
class Trocla::Formats::Sha256crypt < Trocla::Formats::Base
  def format(plain_password,options={})
     plain_password.crypt('$5$' << Trocla::Util.salt << '$')
  end
end
