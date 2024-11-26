require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Trocla::Hooks::Runner" do

  before(:each) do
    expect_any_instance_of(Trocla).to receive(:read_config).and_return(hooks_config)
    @trocla = Trocla.new
  end

  after(:each) do
    Trocla::Hooks.set_messages.clear
    Trocla::Hooks.delete_messages.clear
  end

  describe 'running hooks' do
    describe 'setting password' do
      it "calls the set hook" do
        @trocla.password('random1', 'plain')
        expect(Trocla::Hooks.set_messages.length).to eql(1)
        expect(Trocla::Hooks.delete_messages.length).to eql(0)
        expect(Trocla::Hooks.set_messages.first).to eql("random1_plain")
      end
    end
    describe 'deleting password' do
      it "calls the delete hook" do
        @trocla.delete_password('random1', 'plain')
        expect(Trocla::Hooks.delete_messages.length).to eql(1)
        expect(Trocla::Hooks.set_messages.length).to eql(0)
        expect(Trocla::Hooks.delete_messages.first).to eql("random1_plain")
      end
    end
    describe 'reset password' do
      it "calls the delete and set hook" do
        @trocla.reset_password('random1', 'plain')
        expect(Trocla::Hooks.set_messages.length).to eql(1)
        expect(Trocla::Hooks.set_messages.first).to eql("random1_plain")
        expect(Trocla::Hooks.delete_messages.length).to eql(1)
        expect(Trocla::Hooks.delete_messages.first).to eql("random1_plain")
      end
    end
  end
end
