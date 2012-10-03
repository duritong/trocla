require 'trocla/version'
require 'trocla/util'
require 'trocla/formats'

begin
  require 'sshkey'
rescue LoadError => e
  STDERR.write(":: Error: #{e}\n")
  exit(1)
end

class Trocla

  def initialize(config_file=nil)
    if config_file
      @config_file = File.expand_path(config_file)
    elsif File.exists?(def_config_file=File.expand_path('~/.troclarc.yaml')) || File.exists?(def_config_file=File.expand_path('/etc/troclarc.yaml'))
      @config_file = def_config_file
    end
  end

  # generated and saved the hashed version of the password in some format
  # using the plain password.
  def password(key,format,options={})
    options = config['options'].merge(options)
    raise "Trocla: Format #{format} is not supported! Supported formats: #{Trocla::Formats.all.join(', ')}" unless Trocla::Formats::available?(format)

    # return if previous value found
    unless (password = get_password(key,format)).nil?
      return password
    end

    # previous value not found, we will have to generate them (randomly
    # or from the other value)
    plain_pwd = get_password(key,'plain')
    if options['random'] && !%w{ssh_rsa_public ssh_dsa_public}.include?(format)
      if %w{ssh_rsa ssh_dsa}.include?(format)
        if get_password(key, "#{format}_public")
          raise "Trocla: You can't generate new private key for '#{key}' once its public key does exist"
        else
          k = SSHKey.generate(:type => format.slice(4,5).upcase, :bits => ( options[:bits] || 2048) )
          plain_pwd = k.private_key
          set_password(key,"#{format}_public", k.ssh_public_key)
        end
      elsif plain_pwd.nil?
        plain_pwd = Trocla::Util.random_str(options['length'])
        set_password(key,'plain',plain_pwd) unless format == "plain"
      end
    else
      # previous value not found. we will generate it from the plain
      # password or from the private key
      if %w{ssh_rsa_public ssh_dsa_public}.include?(format)
        private_key = get_password(key, format.slice(0,7))
        raise "Trocla: You request to generate public key for '#{key}' but the private key doesn't exist." if not private_key
        plain_pwd = SSHKey.new(private_key).ssh_public_key
      else
        raise "Trocla: Password must be present as plaintext if you don't want a random password" if plain_pwd.nil?
      end
    end

    set_password(key,format,Trocla::Formats[format].format(plain_pwd,options))
  end

  def get_password(key,format)
    cache.fetch(key,{})[format]
  end

  def reset_password(key,format,options={})
    set_password(key,format,nil)
    password(key,format,options)
  end

  def delete_password(key,format=nil)
    if format.nil?
      cache.delete(key)
    else
      old_val = (h = cache.fetch(key,{})).delete(format)
      h.empty? ? cache.delete(key) : cache[key] = h
      old_val
    end
  end

  def set_password(key,format,password)
    if (format == 'plain')
      h = (cache[key] = { 'plain' => password })
    else
      h = (cache[key] = cache.fetch(key,{}).merge({ format => password }))
    end
    h[format]
  end

  private
  def cache
    @cache ||= build_cache
  end

  def build_cache
    require 'moneta'
    require "moneta/adapters/#{config['adapter'].downcase}"
    lconfig = config
    Moneta::Builder.new { run eval( "Moneta::Adapters::#{lconfig['adapter']}"), lconfig['adapter_options'] }
  end

  def config
    @config ||= read_config
  end

  def read_config
    if @config_file.nil?
      default_config
    else
      raise "Configfile #{@config_file} does not exist!" unless File.exists?(@config_file)
      default_config.merge(YAML.load(File.read(@config_file)))
    end
  end

  def default_config
    require 'yaml'
    f_config = File.expand_path(File.join(File.dirname(__FILE__),'trocla','default_config.yaml'))
    STDERR.puts "Trocla: using default configuration #{f_config}. Use option -c (--config) to overwrite"
    YAML.load(File.read(f_config))
  end

end
