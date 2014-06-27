class Trocla::Formats::Bcrypt < Trocla::Formats::Base
  require 'bcrypt'
  def format(plain_password,options={})
    BCrypt::Password.create(plain_password).to_s
  end
end
