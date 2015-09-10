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
    it "should be able to store random passwords" do
      @trocla.password('random1', 'plain').length.should eql(12)
    end

    it "should be able to store long random passwords" do
      @trocla.set_password('random1_long','plain',4096.times.collect{|s| 'x' }.join('')).length.should eql(4096)
    end

    it "should be able to retrieve stored unencrypted passwords" do
      stored = @trocla.password('random1', 'plain')
      retrieved = @trocla.password('random1', 'plain')
      retrieved_again = @trocla.password('random1', 'plain')
      retrieved.should eql(stored)
      retrieved_again.should eql(stored)
    end

    it "should be able to read unencrypted passwords" do
      @trocla.set_password('some_pass', 'plain', 'super secret')
      @trocla.get_password('some_pass', 'plain').should eql('super secret')
    end

    it "should store plaintext passwords" do
      @trocla.set_password('noplain', 'plain', 'plaintext_password')
      File.readlines(trocla_yaml_file).grep(/plaintext_password/).should eql(["  plain: plaintext_password\n"])
    end
  end
end
