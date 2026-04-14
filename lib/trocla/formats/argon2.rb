class Trocla::Formats::Argon2 < Trocla::Formats::Base
  expensive true
  require 'argon2id'
  def format(plain_password, options = {})
    Argon2id::Password.create(plain_password,**(options['argon2'] || {})).to_s
  end
end
