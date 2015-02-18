$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'mocha'
require 'trocla'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  
end

def default_config
  @default_config ||= YAML.load(File.read(File.expand_path(base_dir+'/lib/trocla/default_config.yaml')))
end

def test_config
  return @config unless @config.nil?
  @config = default_config
  @config.delete('adapter_options')
  @config['adapter'] = :Memory
  @config
end

def ssl_test_config
  return @ssl_config unless @ssl_config.nil?
  @ssl_config = test_config
  @ssl_config['encryption'] = :ssl
  @ssl_config['ssl_options'] = {
    :private_key => data_dir('trocla.key'),
    :public_key  => data_dir('trocla.pub')
  }
  @ssl_config['adapter'] = :YAML
  @ssl_config['adapter_options'] = {
    :file => trocla_yaml_file
  }
  @ssl_config
end

def base_dir
  File.dirname(__FILE__)+'/../'
end

def data_dir(file = nil)
  File.expand_path(File.join(base_dir, 'spec/data', file))
end

def trocla_yaml_file
  data_dir 'trocla_store.yaml'
end

def generate_ssl_keys
  require 'openssl'
  rsa_key = OpenSSL::PKey::RSA.new(4096)
  File.write data_dir('trocla.key'), rsa_key.to_pem
  File.write data_dir('trocla.pub'), rsa_key.public_key.to_pem
end

def remove_ssl_keys
  File.unlink data_dir('trocla.key')
  File.unlink data_dir('trocla.pub')
end

def remove_yaml_store
  File.unlink trocla_yaml_file
end
