class Trocla::Formats::Bcrypt < Trocla::Formats::Base
  expensive true
  require 'bcrypt'
  def format(plain_password,options={})
    BCrypt::Password.create(plain_password, :cost => options['cost']||BCrypt::Engine.cost).to_s
  end
end
