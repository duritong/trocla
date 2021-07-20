require 'open3'
require 'yaml'

class Trocla::Formats::Wireguard < Trocla::Formats::Base
  expensive true

  def format(plain_password, options={})
    if plain_password.match(/---/)
      return YAML.load(plain_password)
    end
    wg_priv = nil
    wg_pub = nil 
    begin
      Open3.popen3('wg genkey') do |stdin, stdout, stderr, waiter|
        wg_priv = stdout.read.chomp
      end
    rescue SystemCallError => e
      if e.message =~ /No such file or directory/
        raise "trocla wireguard: wg binary not found"
      else
        raise "trocla wireguard: #{e.message}"
      end
    end

    begin
      Open3.popen3('wg pubkey') do |stdin, stdout, stderr, waiter|
        stdin.write(wg_priv)
        stdin.close

        wg_pub = stdout.read.chomp
      end
    rescue SystemCallError => e
      raise "trocla wireguard: #{e.message}"
    end
    return YAML.dump({'wg_priv' => wg_priv, 'wg_pub' => wg_pub})
  end

  def render(output, render_options={})
    data = YAML.load(output)
    if render_options['privonly']
      return data['wg_priv']
    elsif render_options['pubonly']
      return data['wg_pub']
    else
      return "pub: " + data['wg_pub'] + "\npriv: " + data['wg_priv'] 
    end
  end
end

