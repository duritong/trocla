$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'rspec/pending_for'
require 'yaml'
require 'trocla'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

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
  it "does not store plaintext passwords" do
    @trocla.set_password('noplain', 'plain', 'plaintext_password')
    expect(File.readlines(trocla_yaml_file).grep(/plaintext_password/)).to be_empty
  end

  it "makes sure identical passwords do not match when stored" do
    @trocla.set_password('one_key', 'plain', 'super secret')
    @trocla.set_password('another_key', 'plain', 'super secret')
    yaml = YAML.load_file(trocla_yaml_file)
    expect(yaml['one_key']['plain']).not_to eq(yaml['another_key']['plain'])
  end
end

RSpec.shared_examples 'store_validation' do |store|
  describe '.get' do
    it { expect(store.get('some_key','plain')).to be_nil }
  end
  describe '.set' do
    it 'stores nil values' do
      store.set('some_nil_value','plain',nil)
      expect(store.get('some_nil_value','plain')).to be_nil
    end
    it 'stores plain format' do
      store.set('some_value','plain','value')
      expect(store.get('some_value','plain')).to eql('value')
    end
    it 'stores other formats' do
      store.set('some_value','foo','bla')
      expect(store.get('some_value','foo')).to eql('bla')
    end
    it 'resets other formats on setting plain' do
      store.set('some_value','foo','bla')
      store.set('some_value','plain','value')
      expect(store.get('some_value','plain')).to eql('value')
      expect(store.get('some_value','foo')).to be_nil
    end
  end
  describe '.delete' do
    it { expect(store.delete('something','foo')).to be_nil }
    it { expect(store.delete('something')).to be_empty }
    it 'deletes the value of a format' do
      store.set('some_value','foo','bla')
      expect(store.delete('some_value','foo')).to eql('bla')
      expect(store.get('some_value','foo')).to be_nil
    end
    it 'deletes only the value of a format' do
      store.set('some_value','plain','value')
      store.set('some_value','foo','bla')
      expect(store.delete('some_value','plain')).to eql('value')
      expect(store.get('some_value','plain')).to be_nil
      expect(store.get('some_value','foo')).to eql('bla')
    end
    it 'deletes all values without a format' do
      store.set('some_value','plain','value')
      store.set('some_value','foo','bla')
      hash = store.delete('some_value')
      expect(hash).to be_a_kind_of(Hash)
      expect(hash['plain']).to eql('value')
      expect(hash['foo']).to eql('bla')
      expect(store.get('some_value','plain')).to be_nil
      expect(store.get('some_value','foo')).to be_nil
    end
  end
  describe 'expiration' do
    it 'will not return an expired key' do
      store.set('some_expiring_value','plain','to_be_expired',{ 'expires' => 2 })
      expect(store.get('some_expiring_value','plain')).to eql('to_be_expired')
      sleep 3
      expect(store.get('some_expiring_value','plain')).to be_nil
    end
    it 'increases expiration when setting anything for that key' do
      store.set('some_expiring_value','plain','to_be_expired',{ 'expires' => 2 })
      expect(store.get('some_expiring_value','plain')).to eql('to_be_expired')
      sleep 1
      store.set('some_expiring_value','bla','bla_to_be_expired',{ 'expires' => 3 })
      sleep 2
      expect(store.get('some_expiring_value','plain')).to eql('to_be_expired')
      sleep 2
      expect(store.get('some_expiring_value','plain')).to be_nil
    end
    it 'keeps expiration when setting another value' do
      store.set('some_expiring_value','plain','to_be_expired',{ 'expires' => 2 })
      store.set('some_expiring_value','foo','to_be_expired_foo')
      expect(store.get('some_expiring_value','plain')).to eql('to_be_expired')
      sleep 3
      expect(store.get('some_expiring_value','plain')).to be_nil
      expect(store.get('some_expiring_value','foo')).to be_nil
    end
    it 'setting plain clears everything including expiration' do
      store.set('some_expiring_value','plain','to_be_expired',{ 'expires' => 2 })
      sleep 1
      store.set('some_expiring_value','plain','to_be_expired2')
      expect(store.get('some_expiring_value','plain')).to eql('to_be_expired2')
      sleep 3
      expect(store.get('some_expiring_value','plain')).to eql('to_be_expired2')
    end
    it 'extends expiration when setting another value' do
      store.set('some_expiring_value','plain','to_be_expired',{ 'expires' => 4 })
      sleep 2
      store.set('some_expiring_value','foo','to_be_expired_foo')
      expect(store.get('some_expiring_value','plain')).to eql('to_be_expired')
      sleep 3
      expect(store.get('some_expiring_value','plain')).to eql('to_be_expired')
      sleep 2
      expect(store.get('some_expiring_value','plain')).to be_nil
    end
    it 'extends expiration when deleting a format' do
      store.set('some_expiring_value','plain','to_be_expired',{ 'expires' => 4 })
      store.set('some_expiring_value','foo','to_be_expired2')
      sleep 2
      expect(store.delete('some_expiring_value','foo')).to eql('to_be_expired2')
      sleep 3
      expect(store.get('some_expiring_value','plain')).to eql('to_be_expired')
      sleep 2
      expect(store.get('some_expiring_value','plain')).to be_nil
    end
    it 'keeps expiration although we\'re fetching a value' do
      store.set('some_expiring_value','plain','to_be_expired',{ 'expires' => 3 })
      sleep 2
      expect(store.get('some_expiring_value','plain')).to eql('to_be_expired')
      sleep 2
      expect(store.get('some_expiring_value','plain')).to be_nil
    end
    it 'readding a value with an expiration makes it expiring in the future' do
      store.set('some_expiring_value','plain','to_be_expired')
      store.set('some_expiring_value','plain','to_be_expired2',{ 'expires' => 2 })
      expect(store.get('some_expiring_value','plain')).to eql('to_be_expired2')
      sleep 3
      expect(store.get('some_expiring_value','plain')).to be_nil
    end
    it 'setting an expires of false removes expiration' do
      store.set('some_expiring_value','plain','to_be_expired2',{ 'expires' => 2 })
      expect(store.get('some_expiring_value','plain')).to eql('to_be_expired2')
      store.set('some_expiring_value','plain','to_be_expired',{ 'expires' => false })
      sleep 3
      expect(store.get('some_expiring_value','plain')).to eql('to_be_expired')
    end
    it 'setting an expires of 0 removes expiration' do
      store.set('some_expiring_value','plain','to_be_expired2',{ 'expires' => 2 })
      expect(store.get('some_expiring_value','plain')).to eql('to_be_expired2')
      store.set('some_expiring_value','plain','to_be_expired',{ 'expires' => 0 })
      sleep 3
      expect(store.get('some_expiring_value','plain')).to eql('to_be_expired')
    end
    it 'setting an expires of false removes expiration even if it\'s for a different format' do
      store.set('some_expiring_value','plain','to_be_expired2',{ 'expires' => 2 })
      expect(store.get('some_expiring_value','plain')).to eql('to_be_expired2')
      store.set('some_expiring_value','foo','to_be_expired_foo',{ 'expires' => false })
      sleep 3
      expect(store.get('some_expiring_value','plain')).to eql('to_be_expired2')
      expect(store.get('some_expiring_value','foo')).to eql('to_be_expired_foo')
    end
    it 'setting an expires of 0 removes expiration even if it\'s for a different format' do
      store.set('some_expiring_value','plain','to_be_expired2',{ 'expires' => 2 })
      expect(store.get('some_expiring_value','plain')).to eql('to_be_expired2')
      store.set('some_expiring_value','foo','to_be_expired_foo',{ 'expires' => 0 })
      sleep 3
      expect(store.get('some_expiring_value','plain')).to eql('to_be_expired2')
      expect(store.get('some_expiring_value','foo')).to eql('to_be_expired_foo')
    end
  end
end

def default_config
  @default_config ||= YAML.load(File.read(File.expand_path(base_dir+'/lib/trocla/default_config.yaml')))
end

def test_config
  @config ||= default_config.merge({
    'store' => :memory,
  })
end

def test_config_persistent
  @config ||= default_config.merge({
    'store_options' => {
      'adapter'         => :YAML,
      'adapter_options' => {
        :file => trocla_yaml_file
      },
    },
  })
end

def ssl_test_config
  @ssl_config ||= test_config_persistent.merge({
    'encryption' => :ssl,
    'encryption_options' => {
      :private_key => data_dir('trocla.key'),
      :public_key  => data_dir('trocla.pub'),
    },
  })
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
class Trocla::Formats::Sleep < Trocla::Formats::Base
  def format(plain_password,options={})
    sleep options['sleep'] ||= 0
    (options['sleep'] + 1 ).times.collect{ plain_password }.join(' ')
  end
end
