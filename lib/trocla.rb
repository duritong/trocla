require 'trocla/version'
require 'trocla/util'
require 'trocla/formats'
require 'trocla/encryptions'

class Trocla

  def initialize(config_file=nil)
    if config_file
      @config_file = File.expand_path(config_file)
    elsif File.exists?(def_config_file=File.expand_path('~/.troclarc.yaml')) || File.exists?(def_config_file=File.expand_path('/etc/troclarc.yaml'))
      @config_file = def_config_file
    end
  end

  def password(key,format,options={})
    # respect a default profile, but let the
    # profiles win over the default options
    options['profiles'] ||= config['options']['profiles']
    if options['profiles']
      options = merge_profiles(options['profiles']).merge(options)
    end
    options = config['options'].merge(options)

    raise "Format #{format} is not supported! Supported formats: #{Trocla::Formats.all.join(', ')}" unless Trocla::Formats::available?(format)

    unless (password=get_password(key,format)).nil?
      return password
    end

    plain_pwd = get_password(key,'plain')
    if options['random'] && plain_pwd.nil?
      plain_pwd = Trocla::Util.random_str(options['length'].to_i,options['charset'])
      set_password(key,'plain',plain_pwd) unless format == 'plain'
    elsif !options['random'] && plain_pwd.nil?
      raise "Password must be present as plaintext if you don't want a random password"
    end
    set_password(key,format,self.formats(format).format(plain_pwd,options))
  end

  def get_password(key, format)
    decrypt(cache.fetch(key, {})[format])
  end

  def reset_password(key,format,options={})
    set_password(key,format,nil)
    password(key,format,options)
  end

  def delete_password(key,format=nil)
    if format.nil?
      decrypt(cache.delete(key))
    else
      old_val = (h = cache.fetch(key,{})).delete(format)
      h.empty? ? cache.delete(key) : cache[key] = h
      decrypt(old_val)
    end
  end

  def set_password(key,format,password)
    if (format == 'plain')
      h = (cache[key] = { 'plain' => encrypt(password) })
    else
      h = (cache[key] = cache.fetch(key,{}).merge({ format => encrypt(password) }))
    end
    decrypt h[format]
  end

  def formats(format)
    (@format_cache||={})[format] ||= Trocla::Formats[format].new(self)
  end

  def encryption
    enc = config['encryption']
    enc ||= :none
    @encryption ||= Trocla::Encryptions[enc].new(self)
    @encryption
  end

  def config
    @config ||= read_config
  end

  private
  def cache
    @cache ||= build_cache
  end

  def build_cache
    require 'moneta'
    lconfig = config
    Moneta.new(lconfig['adapter'], lconfig['adapter_options']||{})
  end

  def read_config
    if @config_file.nil?
      default_config
    else
      raise "Configfile #{@config_file} does not exist!" unless File.exists?(@config_file)
      c = default_config.merge(YAML.load(File.read(@config_file)))
      c['profiles'] = default_config['profiles'].merge(c['profiles'])
      c
    end
  end

  def encrypt(value)
    encryption.encrypt(value)
  end

  def decrypt(value)
    return nil if value.nil?
    encryption.decrypt(value)
  end

  def default_config
    require 'yaml'
    YAML.load(File.read(File.expand_path(File.join(File.dirname(__FILE__),'trocla','default_config.yaml'))))
  end

  def merge_profiles(profiles)
    Array(profiles).inject({}) do |res,profile|
      raise "No such profile #{profile} defined" unless profile_hash = config['profiles'][profile]
      profile_hash.merge(res)
    end
  end

end
