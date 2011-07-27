require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Trocla::Util" do
  describe "random_str" do
    it "should be random" do
      Trocla::Util.random_str.should_not eql(Trocla::Util.random_str)
    end
    
    it "should default to length 12" do
      Trocla::Util.random_str.length.should == 12
    end
    
    it "should be possible to change length" do
      Trocla::Util.random_str(8).length.should == 8
      Trocla::Util.random_str(32).length.should == 32
      Trocla::Util.random_str(1).length.should == 1
    end
  end
end