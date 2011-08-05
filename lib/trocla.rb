require 'trocla/version'
require 'trocla/util'
require 'trocla/formats'

class Trocla
  
  def initialize(config_file=nil)
    if config_file
      @config_file = File.expand_path(config_file)
    elsif File.exists?(def_config_file=File.expand_path('~/.troclarc.yaml')) || File.exists?(def_config_file=File.expand_path('/etc/troclarc.yaml')) 
      @config_file = def_config_file
    end
  end

  def password(key,format,options={})
    options = config['options'].merge(options)
    raise "Format #{format} is not supported! Supported formats: #{Trocla::Formats.all.join(', ')}" unless Trocla::Formats::available?(format)

    unless (password=get_password(key,format)).nil?
      return password
    end

    plain_pwd = get_password(key,'plain') 
    if options['random'] && plain_pwd.nil?
      plain_pwd = Trocla::Util.random_str(options['length'])
      set_password(key,'plain',plain_pwd) unless format == 'plain' 
    elsif !options['random'] && plain_pwd.nil?
      raise "Password must be present as plaintext if you don't want a random password"
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
      YAML.load(File.read(File.expand_path(File.join(File.dirname(__FILE__),'trocla','default_config.yaml'))))
  end
  
end
