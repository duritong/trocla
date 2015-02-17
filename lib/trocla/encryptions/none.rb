class Trocla::Encryptions::None < Trocla::Encryptions::Base
  def encrypt(value)
    value
  end

  def decrypt(value)
    value
  end
end

