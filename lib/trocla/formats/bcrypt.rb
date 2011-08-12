class Trocla::Formats::Bcrypt
  require 'bcrypt'
  def format(plain_password,options={})
    BCrypt::Password.create(plain_password).to_s
  end
end
