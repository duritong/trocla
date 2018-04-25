require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "Trocla::Format::Sshkey" do

  before(:each) do
    expect_any_instance_of(Trocla).to receive(:read_config).and_return(test_config)
    @trocla = Trocla.new
  end

  let(:sshkey_options) do
    {
      'type'    => 'rsa',
      'bits'    => 4096,
      'comment' => 'My ssh key'
    }
  end

  describe "sshkey" do
    it "is able to create an ssh keypair without options" do
      sshkey = @trocla.password('my_ssh_keypair', 'sshkey', {})
      expect(sshkey).to start_with('-----BEGIN RSA PRIVATE KEY-----')
      expect(sshkey).to match(/ssh-/)
    end

    it "is able to create an ssh keypair with options" do
      sshkey = @trocla.password('my_ssh_keypair', 'sshkey', sshkey_options)
      expect(sshkey).to start_with('-----BEGIN RSA PRIVATE KEY-----')
      expect(sshkey).to match(/ssh-/)
      expect(sshkey).to end_with('My ssh key')
    end

    it 'supports fetching only the priv key' do
      sshkey = @trocla.password('my_ssh_keypair', 'sshkey', { 'render' => {'privonly' => true }})
      expect(sshkey).to start_with('-----BEGIN RSA PRIVATE KEY-----')
      expect(sshkey).not_to match(/ssh-/)
    end

    it 'supports fetching only the pub key' do
      sshkey = @trocla.password('my_ssh_keypair', 'sshkey', { 'render' => {'pubonly' => true }})
      expect(sshkey).to start_with('ssh-rsa')
      expect(sshkey).not_to match(/-----BEGIN RSA PRIVATE KEY-----/)
    end

    it "is able to create an ssh keypair with a passphrase" do
      sshkey = @trocla.password('my_ssh_keypair', 'sshkey', { 'passphrase' => 'spec' })
      expect(sshkey).to start_with('-----BEGIN RSA PRIVATE KEY-----')
      expect(sshkey).to match(/ssh-/)
    end

  end

end
