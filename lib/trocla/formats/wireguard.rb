require 'open3'
require 'yaml'

class Trocla::Formats::Wireguard < Trocla::Formats::Base
  expensive true

  def format(plain_password, options={})
    return YAML.safe_load(plain_password) if plain_password.match(/---/)

    wg_priv = nil
    wg_pub = nil
    begin
      Open3.popen3('wg genkey') do |_stdin, stdout, _stderr, _waiter|
        wg_priv = stdout.read.chomp
      end
    rescue SystemCallError => e
      raise 'trocla wireguard: wg binary not found' if e.message =~ /No such file or directory/

      raise "trocla wireguard: #{e.message}"
    end

    begin
      Open3.popen3('wg pubkey') do |stdin, stdout, _stderr, _waiter|
        stdin.write(wg_priv)
        stdin.close

        wg_pub = stdout.read.chomp
      end
    rescue SystemCallError => e
      raise "trocla wireguard: #{e.message}"
    end
    YAML.dump({ 'wg_priv' => wg_priv, 'wg_pub' => wg_pub })
  end

  def render(output, render_options = {})
    data = YAML.safe_load(output)
    if render_options['privonly']
      data['wg_priv']
    elsif render_options['pubonly']
      data['wg_pub']
    else
      'pub: ' + data['wg_pub'] + "\npriv: " + data['wg_priv']
    end
  end
end
