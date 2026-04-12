class Trocla::Formats::Argon2 < Trocla::Formats::Base
  expensive true
  require 'argon2'
  def format(plain_password, options = {})
    Argon2::Password.create(plain_password,options['argon2'] || {})
  end
end
