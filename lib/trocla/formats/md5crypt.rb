# salted crypt
class Trocla::Formats::Md5crypt
  def format(plain_password,options={})
     plain_password.crypt('$1$' << Trocla::Util.random_str(8) << '$')
  end
end