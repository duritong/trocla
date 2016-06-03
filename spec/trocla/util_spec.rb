require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Trocla::Util" do

  { :random_str => 12, :salt => 8 }.each do |m,length|
    describe m do
      it "is random" do
        expect(Trocla::Util.send(m)).not_to eq(Trocla::Util.send(m))
      end

      it "defaults to length #{length}" do
        expect(Trocla::Util.send(m).length).to eq(length)
      end

      it "is possible to change length" do
        expect(Trocla::Util.send(m,8).length).to eq(8)
        expect(Trocla::Util.send(m,32).length).to eq(32)
        expect(Trocla::Util.send(m,1).length).to eq(1)
      end
    end
  end

  describe :numeric_generator do
    10.times.each do |i|
      it "creates random numeric password #{i}" do
        expect(Trocla::Util.random_str(12, 'numeric')).to match(/^[0-9]{12}$/)
      end
    end
  end

  describe :hexadecimal_generator do
    10.times.each do |i|
      it "creates random hexadecimal password #{i}" do
        expect(Trocla::Util.random_str(12, 'hexadecimal')).to match(/^[0-9a-f]{12}$/)
      end
    end
  end

  describe :typesafe_generator do
    10.times.each do |i|
      it "creates random typesafe password #{i}" do
        expect(Trocla::Util.random_str(12, 'typesafe')).to match(/^[1-9a-hj-km-xA-HJ-KM-X]{12}$/)
      end
    end
  end

  describe :salt do
    10.times.each do |i|
      it "contains only characters and numbers #{i}" do
        expect(Trocla::Util.salt).to match(/^[a-z0-9]+$/i)
      end
    end
  end
end
