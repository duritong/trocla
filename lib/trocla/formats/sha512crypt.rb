# salted crypt
class Trocla::Formats::Sha512crypt
  def format(plain_password,options={})
     plain_password.crypt('$6$' << Trocla::Util.random_str(8) << '$')
  end
end
