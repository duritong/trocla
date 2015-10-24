require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "Trocla::Encryptions::None" do

  before(:each) do
    expect_any_instance_of(Trocla).to receive(:read_config).and_return(test_config_persistent)
    @trocla = Trocla.new
  end

  after(:each) do
    remove_yaml_store
  end

  describe "none" do
    include_examples 'encryption_basics'

    it "should store plaintext passwords" do
      @trocla.set_password('noplain', 'plain', 'plaintext_password')
      File.readlines(trocla_yaml_file).grep(/plaintext_password/).should eql(["  plain: plaintext_password\n"])
    end
  end
end
