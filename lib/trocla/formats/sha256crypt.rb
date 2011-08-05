# salted crypt
class Trocla::Formats::Sha256crypt
  def format(plain_password,options={})
     plain_password.crypt('$5$' << Trocla::Util.random_str(8) << '$')
  end
end
