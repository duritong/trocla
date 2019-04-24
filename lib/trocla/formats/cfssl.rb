class Trocla::Formats::Cfssl < Trocla::Formats::Base
  require 'json'
  require 'open3'
  def format(plain_password,options={})
    #no dig method on jruby 1.9 used by puppet ;/
    if @trocla.config['formats'] && @trocla.config['formats']['cfssl']
      @cfssl_config = @trocla.config['formats']['cfssl']
    else
      raise "cfssl format needs server parameters in formats -> cfssl config in the config file"
    end
    if !options.is_a?(Hash)
      options = YAML.load(options)
    end
    selfsigned = false
    if options['selfsigned']
      selfsigned = true
      options.delete('selfsigned')
    end
    options['names'] ||= @cfssl_config['default_names']
    options['key'] ||= @cfssl_config['default_key'] || { 'algo' => 'rsa', 'size' => 2048 }
    if selfsigned
      options['profile'] ||= 'ca'
    else
      options['profile'] ||= 'server'
    end


    if plain_password.is_a?(Hash) && plain_password['cert'] && plain_password['key']
      # looks like cert, just an import, don't generate any new keys
      return plain_password
    end
    @cfssl_config['cfssl_config_path'] ||= File.expand_path(File.join(File.dirname(__FILE__),'..','ca-config.json'))
    if !options['CN'] || !options['names'] || !options['hosts']
       raise "options passed should contain CN, hosts, and names (if names are not defined in default config)"
    end
    json_csr = JSON.dump(options)
    if selfsigned
      cfssl_cmd = ['cfssl','gencert','-initca=true','-config',@cfssl_config['cfssl_config_path'],'-profile', options['profile'], '-']
    else
      cfssl_cmd = ['cfssl','gencert','-config',@cfssl_config['cfssl_config_path'],'-profile', options['profile'], '-remote',@cfssl_config['server_url'],'-']
    end
    cfssl_stdout,cfssl_stderr = Open3.capture3(
        *cfssl_cmd,
        :stdin_data=>json_csr
    )
    certdata = JSON.load(cfssl_stdout)
    if !certdata.is_a?(Hash) || !certdata['cert']
      raise "cfssl: did not get cert data from server: stdin: #{json_csr} -> stdout: #{cfssl_stdout}, stderr #{cfssl_stderr}, config:#{@cfssl_config['cfssl_config_path']}"
    end
    if @cfssl_config['intermediates'] || options['intermediates']
      certdata['intermediate'] ||= options['intermediates'] || @cfssl_config['intermediates']
    end
    # parse cert and extract validity date
    cert = OpenSSL::X509::Certificate.new certdata['cert']
    certdata['not_before'] = cert.not_before
    certdata['not_after'] = cert.not_after
    return certdata
  end
end
