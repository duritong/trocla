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
  yaml_path = File.expand_path(base_dir+'/spec/data/test_config.yaml')
  File.unlink(yaml_path) if File.exists?(yaml_path)
  @config['adapter_options'][:path] = yaml_path
  @config
end

def base_dir
  File.dirname(__FILE__)+'/../'
end
