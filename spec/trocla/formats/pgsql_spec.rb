require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe 'Trocla::Format::Pgsql' do
  before(:each) do
    expect_any_instance_of(Trocla).to receive(:read_config).and_return(test_config)
    @trocla = Trocla.new
  end

  describe 'default pgsql' do
    it 'create a pgsql password keypair without options in sha256' do
      pass = @trocla.password('pgsql_password_sh256', 'pgsql', {})
      expect(pass).to match(/^SCRAM-SHA-256\$(.*):(.*)\$(.*):/)
    end
  end

  describe 'pgsql in md5 encode' do
    it 'create a pgsql password in md5 encode' do
      pass = @trocla.password(
        'pgsql_password_md5', 'pgsql',
        { 'username' => 'toto', 'encode' => 'md5' }
      )
      expect(pass).to match(/^md5/)
    end
  end
end
