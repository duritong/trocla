require 'sshkey'

class Trocla::Formats::Sshkey < Trocla::Formats::Base

  expensive true

  def format(plain_password,options={})

    if plain_password.match(/-----BEGIN RSA PRIVATE KEY-----.*-----END RSA PRIVATE KEY/m)
      # Import, validate ssh key
      begin
        sshkey = ::SSHKey.new(plain_password)
      rescue Exception => e
        raise "SSH key import failed: #{e.message}"
      end
      return sshkey.private_key + sshkey.ssh_public_key
    end

    type = options['type'] || 'rsa'
    bits = options['bits'] || 2048

    begin
      sshkey = ::SSHKey.generate(
        type:       type,
        bits:       bits,
        comment:    options['comment'],
        passphrase: options['passphrase']
      )
    rescue Exception => e
      raise "SSH key creation failed: #{e.message}"
    end

    sshkey.private_key + sshkey.ssh_public_key
  end

  def render(output,render_options={})
    if render_options['privonly']
      ::SSHKey.new(output).private_key
    elsif render_options['pubonly']
      ::SSHKey.new(output).ssh_public_key
    else
      super(output,render_options)
    end
  end

end
