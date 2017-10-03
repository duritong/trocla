require 'trocla/version'
require 'trocla/util'
require 'trocla/formats'
require 'trocla/encryptions'
require 'trocla/stores'

class Trocla
  def initialize(config_file=nil)
    if config_file
      @config_file = File.expand_path(config_file)
    elsif File.exists?(def_config_file=File.expand_path('~/.troclarc.yaml')) || File.exists?(def_config_file=File.expand_path('/etc/troclarc.yaml'))
      @config_file = def_config_file
    end
  end

  def self.open(config_file=nil)
    trocla = Trocla.new(config_file)

    if block_given?
      yield trocla
      trocla.close
    else
      trocla
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

    unless (password=get_password(key,format,options)).nil?
      return password
    end

    plain_pwd = get_password(key,'plain',options)
    if options['random'] && plain_pwd.nil?
      plain_pwd = Trocla::Util.random_str(options['length'].to_i,options['charset'])
      set_password(key,'plain',plain_pwd,options) unless format == 'plain'
    elsif !options['random'] && plain_pwd.nil?
      raise "Password must be present as plaintext if you don't want a random password"
    end
    pwd = self.formats(format).format(plain_pwd,options)
    # it's possible that meanwhile another thread/process was faster in
    # formating the password. But we want todo that second lookup
    # only for expensive formats
    if self.formats(format).expensive?
      get_password(key,format,options) || set_password(key, format, pwd, options)
    else
      set_password(key, format, pwd, options)
    end
  end

  def get_password(key, format, options={})
    render(format,decrypt(store.get(key,format)),options)
  end

  def reset_password(key,format,options={})
    set_password(key,format,nil,options)
    password(key,format,options)
  end

  def delete_password(key,format=nil,options={})
    v = store.delete(key,format)
    if v.is_a?(Hash)
      Hash[*v.map do |f,encrypted_value|
        [f,render(format,decrypt(encrypted_value),options)]
      end.flatten]
    else
      render(format,decrypt(v),options)
    end
  end

  def set_password(key,format,password,options={})
    store.set(key,format,encrypt(password),options)
    render(format,password,options)
  end

  def available_format(key, options={})
    render(false,decrypt(store.format(key)),options)
  end

  def search_key(key, options={})
    render(false,decrypt(store.search(key)),options)
  end

  def formats(format)
    (@format_cache||={})[format] ||= Trocla::Formats[format].new(self)
  end

  def encryption
    @encryption ||= Trocla::Encryptions[config['encryption']].new(config['encryption_options'],self)
  end

  def config
    @config ||= read_config
  end

  def close
    store.close
  end

  private
  def store
    @store ||= build_store
  end

  def build_store
    s = config['store']
    clazz = if s.is_a?(Symbol)
      Trocla::Stores[s]
    else
      require config['store_require'] if config['store_require']
      eval(s)
    end
    clazz.new(config['store_options'],self)
  end

  def read_config
    if @config_file.nil?
      default_config
    else
      raise "Configfile #{@config_file} does not exist!" unless File.exists?(@config_file)
      c = default_config.merge(YAML.load(File.read(@config_file)))
      c['profiles'] = default_config['profiles'].merge(c['profiles'])
      # migrate all options to new store options
      # TODO: remove workaround in 0.3.0
      c['store_options']['adapter'] = c['adapter'] if c['adapter']
      c['store_options']['adapter_options'] = c['adapter_options'] if c['adapter_options']
      c['encryption_options'] = c['ssl_options'] if c['ssl_options']
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

  def render(format,output,options={})
    if format && output && f=self.formats(format)
      f.render(output,options['render']||{})
    else
      output
    end
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
