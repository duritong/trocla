class Trocla::Formats::SshRsa

  def format(plain_password,options={})
    raise "Trocla: #{self.class.name} can't be generated from a password. Please use `set` instead."
  end

end
