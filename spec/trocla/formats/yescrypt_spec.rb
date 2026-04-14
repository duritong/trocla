require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe 'Trocla::Format::Yescrypt' do
  before(:each) do
    expect_any_instance_of(Trocla).to receive(:read_config).and_return(test_config)
    @trocla = Trocla.new
  end

  describe 'default yescrypt' do
    it 'create a yescrypt hash' do
      pass = @trocla.password('yescrypt_password', 'yescrypt', {})
      expect(pass).to match(/^\$y\$/)
    end
  end

  describe 'yescrpyt with cost' do
    it 'create a yescrypt with the higher cost' do
      pass = @trocla.password(
        'yescrypt_password_unsafe', 'yescrypt',
        { 'cost' => 11 }
      )
      expect(pass).to match(/^\$y\$/)
    end
    it 'raises an error with a wrong cost factor' do
      expect {
        @trocla.password(
          'yescrypt_password_unsafe', 'yescrypt',
          { 'cost' => 12 }
        )
      }.to raise_error(/Unsupported cost factor/)
    end
  end
end
