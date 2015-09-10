require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require 'date'

describe "Trocla::Format::X509" do

  before(:each) do
    expect_any_instance_of(Trocla).to receive(:read_config).and_return(test_config)
    @trocla = Trocla.new
  end

  let(:ca_options) do
    {
      'CN'        => 'This is my self-signed certificate which doubles as CA',
      'become_ca' => true,
    }
  end
  let(:cert_options) do
    {
      'ca'       => 'my_shiny_selfsigned_ca',
      'subject'  => '/C=ZZ/O=Trocla Inc./CN=test/emailAddress=example@example.com',
    }
  end

  describe "x509 selfsigned" do
    it "should be able to create self signed cert without being a ca by default" do
      ca_str = @trocla.password('my_shiny_selfsigned_ca', 'x509', {
        'CN'        => 'This is my self-signed certificate',
        'become_ca' => false,
      })
      ca = OpenSSL::X509::Certificate.new(ca_str)
      # selfsigned?
      ca.issuer.should eql(ca.subject)

      ca.extensions.find{|e| e.oid == 'basicConstraints' }.value.should eql('CA:FALSE')
      ku = ca.extensions.find{|e| e.oid == 'keyUsage' }.value
      ku.should_not match(/Certificate Sign/)
      ku.should_not match(/CRL Sign/)
    end

    it "should be able to create a self signed cert that is a CA" do
      ca_str = @trocla.password('my_shiny_selfsigned_ca', 'x509', ca_options)
      ca = OpenSSL::X509::Certificate.new(ca_str)
      # selfsigned?
      ca.issuer.should eql(ca.subject)

      ca.extensions.find{|e| e.oid == 'basicConstraints' }.value.should eql('CA:TRUE')
      ku = ca.extensions.find{|e| e.oid == 'keyUsage' }.value
      ku.should match(/Certificate Sign/)
      ku.should match(/CRL Sign/)
    end

  end
  describe "x509 signed by a ca" do
    before(:each) do
      ca_str = @trocla.password('my_shiny_selfsigned_ca', 'x509', ca_options)
      @ca = OpenSSL::X509::Certificate.new(ca_str)
    end
    it 'shold be able to get a cert signed by the ca' do
      cert_str = @trocla.password('mycert', 'x509', cert_options)
      cert = OpenSSL::X509::Certificate.new(cert_str)
      cert.issuer.should eql(@ca.subject)

      cert.extensions.find{|e| e.oid == 'basicConstraints' }.value.should eql('CA:FALSE')
      ku = cert.extensions.find{|e| e.oid == 'keyUsage' }.value
      ku.should_not match(/Certificate Sign/)
      ku.should_not match(/CRL Sign/)
    end

    it 'shold be able to get a cert signed by the ca that is again a ca' do
      cert_str = @trocla.password('mycert', 'x509', cert_options.merge({
        'become_ca' => true,
      }))
      cert = OpenSSL::X509::Certificate.new(cert_str)
      cert.issuer.should eql(@ca.subject)

      cert.extensions.find{|e| e.oid == 'basicConstraints' }.value.should eql('CA:TRUE')
      ku = cert.extensions.find{|e| e.oid == 'keyUsage' }.value
      ku.should match(/Certificate Sign/)
      ku.should match(/CRL Sign/)
    end

    it 'shold be able to get a cert signed by the ca that is again a ca that is able to sign certs' do
      cert_str = @trocla.password('mycert_and_ca', 'x509', cert_options.merge({
        'become_ca' => true,
      }))
      cert = OpenSSL::X509::Certificate.new(cert_str)
      cert.issuer.should eql(@ca.subject)

      cert2_str = @trocla.password('mycert', 'x509', {
        'ca'        => 'mycert_and_ca',
        'subject'   => '/C=ZZ/O=Trocla Inc./CN=test2/emailAddress=example@example.com',
        'become_ca' => true,
      })
      cert2 = OpenSSL::X509::Certificate.new(cert2_str)
      cert2.issuer.should eql(cert.subject)
    end

    it 'should respect all options' do
      co = cert_options.merge({
        'hash'         => 'sha1',
        'keysize'      => 4096,
        'serial'       => 123456789,
        'days'         => 3650,
        'subject'      => nil,
        'C'            => 'AA',
        'ST'           => 'Earth',
        'L'            => 'Here',
        'O'            => 'SSLTrocla',
        'OU'           => 'root',
        'CN'           => 'www.test',
        'emailAddress' => 'test@example.com',
        'altnames'     => [ 'test', 'test1', 'test2', 'test3' ],
      })
      cert_str = @trocla.password('mycert', 'x509', co)
      cert = OpenSSL::X509::Certificate.new(cert_str)
      cert.issuer.should eql(@ca.subject)
      ['C','ST','L','O','OU','CN','emailAddress'].each do |field|
        cert.subject.to_s.should match(/#{field}=#{co[field]}/)
      end
      cert.signature_algorithm.should eql('sha1WithRSAEncryption')
      cert.serial.should eql(123456789)
      cert.not_before.should < Time.now
      Date.parse(cert.not_after.to_s) == Date.parse((Time.now+3650*24*60*60).to_s)
      # https://stackoverflow.com/questions/13747212/determine-key-size-from-public-key-pem-format
      (cert.public_key.n.num_bytes * 8).should eql(4096)
      cert.extensions.find{|e| e.oid == 'subjectAltName' }.value.should eql('DNS:test, DNS:test1, DNS:test2, DNS:test3')

      cert.extensions.find{|e| e.oid == 'basicConstraints' }.value.should eql('CA:FALSE')
      ku = cert.extensions.find{|e| e.oid == 'keyUsage' }.value
      ku.should_not match(/Certificate Sign/)
      ku.should_not match(/CRL Sign/)
    end

    it 'should prefer full subject of single subject parts' do
      co = cert_options.merge({
        'C'            => 'AA',
        'ST'           => 'Earth',
        'L'            => 'Here',
        'O'            => 'SSLTrocla',
        'OU'           => 'root',
        'CN'           => 'www.test',
        'emailAddress' => 'test@example.com',
      })
      cert_str = @trocla.password('mycert', 'x509', co)
      cert = OpenSSL::X509::Certificate.new(cert_str)
      ['C','ST','L','O','OU','CN','emailAddress'].each do |field|
        cert.subject.to_s.should_not match(/#{field}=#{co[field]}/)
      end
    end
  end
end
