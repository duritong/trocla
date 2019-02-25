require 'tmpdir'
require 'json'
require 'open3'
class Trocla::Formats::Cfssl < Trocla::Formats::Base
  expensive true
  def format(plain_password,options={})
    # dig not used because JRuby 1.9 (used by puppet) doesn't support it
    if @trocla.config['formats'] && @trocla.config['formats']['cfssl']
      @cfssl_config = @trocla.config['formats']['cfssl']
    else
       raise "cfssl format needs server parameters in formats -> cfssl config in the config file"
    end
    if plain_password.is_a?(Hash) && plain_password['cert'] && plain_password['key']
       # just an import, don't generate any new keys
       # TODO check cert expiry ?
       plain_password['intermediate'] ||= options['intermediates'] || @cfssl_config['intermediates']
      return plain_password
    end
    options['names'] ||= @cfssl_config['default_names']
    options['key'] ||= @cfssl_config['default_key'] ||  { 'algo' => 'rsa', 'size' => 2048 }
    @cfssl_config['cfssl_config_path'] ||= File.expand_path(File.join(File.dirname(__FILE__),'..','ca-config.json'))
    if !options['CN'] || !options['names'] || !options['hosts']
       raise "options passed should contain CN, hosts, and names (if names are not defined in default config)"
    end
    json_csr = JSON.dump(options)
    cfssl_stdout,cfssl_stderr = Open3.capture3(
        ['cfssl','gencert', '-remote',@cfssl_config['server_url'],'-config',@cfssl_config['cfssl_config_path'], '-profile', options['profile']||'server', '-'].join(' '),
        :stdin_data=>json_csr
    )
    certdata = JSON.load(cfssl_stdout)
    if !certdata.is_a?(Hash) || !certdata['cert']
      raise "cfssl: did not get cert data from server: stdin: #{json_csr} -> stdout: #{cfssl_stdout}, stderr #{cfssl_stderr}, config:#{@cfssl_config['cfssl_config_path']}"
    end
    if @cfssl_config['intermediates'] || options['intermediates']
      certdata['intermediate'] ||= options['intermediates'] || @cfssl_config['intermediates']
    end
    return certdata
end
end