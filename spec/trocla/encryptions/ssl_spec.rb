require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "Trocla::Encryptions::Ssl" do

  before(:all) do
    generate_ssl_keys
  end

  after(:all) do
    remove_ssl_keys
  end

  before(:each) do
    expect_any_instance_of(Trocla).to receive(:read_config).and_return(ssl_test_config)
    @trocla = Trocla.new
  end

  after(:each) do
    remove_yaml_store
  end

  describe "encrypt" do
    include_examples 'encryption_basics'
    include_examples 'verify_encryption'
  end
end
