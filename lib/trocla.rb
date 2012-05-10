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

  # icy: THESE COMMENTS FOCUS ON SSH KEY SUPPORT ONLY
  # icy:
  # icy: this function will return the password if there is one
  # icy: and it will create new password if there is not. this is a bit
  # icy: confused, as it has the roles of both methods `get_password`
  # icy: and `set_password`. Please note that, in the binary file `bin/trocla`,
  # icy: the invoking `create` will call this method `password` to generate
  # icy: new password. Because this method will call `set_password`, the
  # icy: method `set_password` is considered as an internal form. This method
  # icy: is simply write the password without any checking. In sort
  # icy: this method: will generate the password if there is missing
  # icy: and will write the password to the cache file
  # icy:
  # icy: there are four cases
  # icy:   random,     plain nil      : acceptable, will generate new one
  # icy:   random,     plain not nil  : (return) => overwrite it ^^
  # icy:   not random, plain nil      : un accetaple
  # icy:   not random, plain not nil  : (return)
  # icy:
  # icy: we don't assume that there is a relation between 'formartted'    <SSH
  # icy: version and the 'plain' version of any password. Such relation   <SSH
  # icy: will be handled by the format function and we won't check.       <SSH
  #
  def password(key,format,options={})
    options = config['options'].merge(options)
    raise "Format #{format} is not supported! Supported formats: #{Trocla::Formats.all.join(', ')}" unless Trocla::Formats::available?(format)

    # if the previous value does exist, just return it.
    if not options['random'] and not (password = get_password(key,format)).nil?
      return password unless %w{sshdsa sshrsa}.include?(format)
    end

    plain_pwd = get_password(key,'plain')
    if options['random']
      if %w{ssh_rsa ssh_dsa}.include?(format)
        begin
          require 'sshkey'
        rescue LoadError => e
          STDOUT.write(":: Error: #{e}\n")
          exit(1)
        end
        k = SSHKey.generate(:type => format.slice(4,5).upcase, :bits => ( options[:bits] || 2048) )
        # FIXME: * we store only the private key. The public key can be       <SSH
        # FIXME:   generated from the private key at any time. Though we      <SSH
        # FIXME:   can do some tricks in `trocla`, they may make the code     <SSH
        # FIXME:   at bit messy -- due to the fact the method `get_password`  <SSH
        # FIXME:   has not any option.                                        <SSH
        # FIXME: * we won't alter the plain string --- 'plain' means          <SSH
        # FIXME:   nothing in the case of 'ssh-*'                             <SSH
        # FIXME:   we can use 'plain' to store the password of the key        <SSH
        plain_pwd = k.private_key
        set_password(key,"#{format}_public", k.public_key)
        puts k.public_key
      else # FIXME: if plain_pwd.nil?
        plain_pwd = Trocla::Util.random_str(options['length'])
        set_password(key,'plain',plain_pwd) unless %w{plain}.include?(format)
      end
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
