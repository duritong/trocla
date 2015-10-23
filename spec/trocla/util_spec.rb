require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Trocla::Util" do

  { :random_str => 12, :salt => 8 }.each do |m,length|
    describe m do
      it "should be random" do
        Trocla::Util.send(m).should_not eql(Trocla::Util.send(m))
      end

      it "should default to length #{length}" do
        Trocla::Util.send(m).length.should == length
      end

      it "should be possible to change length" do
        Trocla::Util.send(m,8).length.should == 8
        Trocla::Util.send(m,32).length.should == 32
        Trocla::Util.send(m,1).length.should == 1
      end
    end
  end

  describe :numeric_generator do
    10.times.each do |i|
      it "should create random numeric password #{i}" do
        Trocla::Util.random_str(12, 'numeric' ).should =~ /^[0-9]{12}$/
      end
    end
  end

  describe :salt do
    10.times.each do |i|
      it "should only contain characters and numbers #{i}" do
        Trocla::Util.salt =~ /^[a-z0-9]+$/i
      end
    end
  end
end
