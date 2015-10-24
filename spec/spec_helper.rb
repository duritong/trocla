$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'mocha'
require 'yaml'
require 'trocla'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|

end

RSpec.shared_examples "encryption_basics" do
  describe 'storing' do
    it "random passwords" do
      expect(@trocla.password('random1', 'plain').length).to eql(16)
    end

    it "long random passwords" do
      expect(@trocla.set_password('random1_long','plain',4096.times.collect{|s| 'x' }.join('')).length).to eql(4096)
    end
  end

  describe 'retrieve' do
    it "random passwords" do
      stored = @trocla.password('random1', 'plain')
      retrieved = @trocla.password('random1', 'plain')
      retrieved_again = @trocla.password('random1', 'plain')
      expect(retrieved).to eql(stored)
      expect(retrieved_again).to eql(stored)
      expect(retrieved_again).to eql(retrieved)
    end

    it "encrypted passwords" do
      @trocla.set_password('some_pass', 'plain', 'super secret')
      expect(@trocla.get_password('some_pass', 'plain')).to eql('super secret')
    end

  end
  describe 'deleting' do
    it "plain" do
      @trocla.set_password('some_pass', 'plain', 'super secret')
      expect(@trocla.delete_password('some_pass', 'plain')).to eql('super secret')
    end
    it "delete formats" do
      plain = @trocla.password('some_mysqlpass', 'plain')
      mysql = @trocla.password('some_mysqlpass', 'mysql')
      expect(@trocla.delete_password('some_mysqlpass', 'mysql')).to eql(mysql)
      expect(@trocla.delete_password('some_mysqlpass', 'plain')).to eql(plain)
      expect(@trocla.get_password('some_mysqlpass','plain')).to be_nil
      expect(@trocla.get_password('some_mysqlpass','mysql')).to be_nil
    end

    it "all passwords" do
      plain = @trocla.password('some_mysqlpass', 'plain')
      mysql = @trocla.password('some_mysqlpass', 'mysql')
      deleted = @trocla.delete_password('some_mysqlpass')
      expect(deleted).to be_a_kind_of(Hash)
      expect(deleted['plain']).to eql(plain)
      expect(deleted['mysql']).to eql(mysql)
    end
  end
end
RSpec.shared_examples "verify_encryption" do
  it "should not store plaintext passwords" do
    @trocla.set_password('noplain', 'plain', 'plaintext_password')
    File.readlines(trocla_yaml_file).grep(/plaintext_password/).should be_empty
  end

  it "should make sure identical passwords do not match when stored" do
    @trocla.set_password('one_key', 'plain', 'super secret')
    @trocla.set_password('another_key', 'plain', 'super secret')
    yaml = YAML.load_file(trocla_yaml_file)
    yaml['one_key']['plain'].should_not eql(yaml['another_key']['plain'])
  end
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

def test_config_persistent
  return @config unless @config.nil?
  @config = default_config
  @config['adapter'] = :YAML
  @config['adapter_options'] = {
    :file => trocla_yaml_file
  }
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
  data_dir('trocla_store.yaml')
end

def generate_ssl_keys
  require 'openssl'
  rsa_key = OpenSSL::PKey::RSA.new(4096)
  File.open(data_dir('trocla.key'), 'w') { |f| f.write(rsa_key.to_pem) }
  File.open(data_dir('trocla.pub'), 'w') { |f| f.write(rsa_key.public_key.to_pem) }
end

def remove_ssl_keys
  File.unlink(data_dir('trocla.key'))
  File.unlink(data_dir('trocla.pub'))
end

def remove_yaml_store
  File.unlink(trocla_yaml_file)
end
