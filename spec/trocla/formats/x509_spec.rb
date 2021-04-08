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

  def verify(ca,cert)
    store =  OpenSSL::X509::Store.new
    store.purpose = OpenSSL::X509::PURPOSE_SSL_CLIENT
    Array(ca).each do |c|
      store.add_cert(c)
    end
    store.verify(cert)
  end

  describe "x509 selfsigned" do
    it "is able to create self signed cert without being a ca by default" do
      cert_str = @trocla.password('my_shiny_selfsigned_ca', 'x509', {
        'CN'        => 'This is my self-signed certificate',
        'become_ca' => false,
      })
      cert = OpenSSL::X509::Certificate.new(cert_str)
      # selfsigned?
      expect(cert.issuer.to_s).to eq(cert.subject.to_s)
      # default size
      # https://stackoverflow.com/questions/13747212/determine-key-size-from-public-key-pem-format
      expect(cert.public_key.n.num_bytes * 8).to eq(4096)
      expect((Date.parse(cert.not_after.localtime.to_s) - Date.today).to_i).to eq(365)
      # it's a self signed cert and NOT a CA
      expect(verify(cert,cert)).to be false

      v = cert.extensions.find{|e| e.oid == 'basicConstraints' }.value
      expect(v).to eq('CA:FALSE')
      # we want to include only CNs that look like a DNS name
      expect(cert.extensions.find{|e| e.oid == 'subjectAltName' }).to be_nil
      ku = cert.extensions.find{|e| e.oid == 'keyUsage' }.value
      expect(ku).not_to match(/Certificate Sign/)
      expect(ku).not_to match(/CRL Sign/)
    end

    it "is able to create a self signed cert that is a CA" do
      ca_str = @trocla.password('my_shiny_selfsigned_ca', 'x509', ca_options)
      ca = OpenSSL::X509::Certificate.new(ca_str)
      # selfsigned?
      expect(ca.issuer.to_s).to eq(ca.subject.to_s)
      expect((Date.parse(ca.not_after.localtime.to_s) - Date.today).to_i).to eq(365)
      expect(verify(ca,ca)).to be true

      v = ca.extensions.find{|e| e.oid == 'basicConstraints' }.value
      expect(v).to eq('CA:TRUE')
      ku = ca.extensions.find{|e| e.oid == 'keyUsage' }.value
      expect(ku).to match(/Certificate Sign/)
      expect(ku).to match(/CRL Sign/)
    end
    it "is able to create a self signed cert without any keyUsage restrictions" do
      cert_str = @trocla.password('my_shiny_selfsigned_without restrictions', 'x509', {
        'CN'         => 'This is my self-signed certificate',
        'key_usages' => [],
      })
      cert = OpenSSL::X509::Certificate.new(cert_str)
      # selfsigned?
      expect(cert.issuer.to_s).to eq(cert.subject.to_s)
      # default size
      # https://stackoverflow.com/questions/13747212/determine-key-size-from-public-key-pem-format
      expect(cert.public_key.n.num_bytes * 8).to eq(4096)
      expect((Date.parse(cert.not_after.localtime.to_s) - Date.today).to_i).to eq(365)
      # it's a self signed cert and NOT a CA, but has no keyUsage limitation
      expect(verify(cert,cert)).to be true

      v = cert.extensions.find{|e| e.oid == 'basicConstraints' }.value
      expect(v).to_not eq('CA:TRUE')
      expect(cert.extensions.find{|e| e.oid == 'keyUsage' }).to be_nil
    end

    it "is able to create a self signed cert with custom keyUsage restrictions" do
      cert_str = @trocla.password('my_shiny_selfsigned_without restrictions', 'x509', {
        'CN'         => 'This is my self-signed certificate',
        'key_usages' => [ 'cRLSign', ],
      })
      cert = OpenSSL::X509::Certificate.new(cert_str)
      # selfsigned?
      expect(cert.issuer.to_s).to eq(cert.subject.to_s)
      # default size
      # https://stackoverflow.com/questions/13747212/determine-key-size-from-public-key-pem-format
      expect(cert.public_key.n.num_bytes * 8).to eq(4096)
      expect((Date.parse(cert.not_after.localtime.to_s) - Date.today).to_i).to eq(365)
      # it's a self signed cert and NOT a CA, as it's key is restricted to only CRL Sign
      expect(verify(cert,cert)).to be false

      v = cert.extensions.find{|e| e.oid == 'basicConstraints' }.value
      expect(v).to_not eq('CA:TRUE')
      ku = cert.extensions.find{|e| e.oid == 'keyUsage' }.value
      expect(ku).to match(/CRL Sign/)
      expect(ku).not_to match(/Certificate Sign/)
    end

  end
  describe "x509 signed by a ca" do
    before(:each) do
      ca_str = @trocla.password('my_shiny_selfsigned_ca', 'x509', ca_options)
      @ca = OpenSSL::X509::Certificate.new(ca_str)
    end
    it 'is able to get a cert signed by the ca' do
      cert_str = @trocla.password('mycert', 'x509', cert_options)
      cert = OpenSSL::X509::Certificate.new(cert_str)
      expect(cert.issuer.to_s).to eq(@ca.subject.to_s)
      expect((Date.parse(cert.not_after.localtime.to_s) - Date.today).to_i).to eq(365)
      expect(verify(@ca,cert)).to be true

      v = cert.extensions.find{|e| e.oid == 'basicConstraints' }.value
      expect(v).to eq('CA:FALSE')
      ku = cert.extensions.find{|e| e.oid == 'keyUsage' }.value
      expect(ku).not_to match(/Certificate Sign/)
      expect(ku).not_to match(/CRL Sign/)
    end

    it 'supports fetching only the key' do
      cert_str = @trocla.password('mycert', 'x509', cert_options.merge('render' => {'keyonly' => true }))
      expect(cert_str).not_to match(/-----BEGIN CERTIFICATE-----/)
      expect(cert_str).to match(/-----BEGIN RSA PRIVATE KEY-----/)
    end
    it 'supports fetching only the publickey' do
      pkey_str = @trocla.password('mycert', 'x509', cert_options.merge('render' => {'publickeyonly' => true }))
      expect(pkey_str).not_to match(/-----BEGIN CERTIFICATE-----/)
      expect(pkey_str).to match(/-----BEGIN PUBLIC KEY-----/)
    end
    it 'supports fetching only the cert' do
      cert_str = @trocla.password('mycert', 'x509', cert_options.merge('render' => {'certonly' => true }))
      expect(cert_str).to match(/-----BEGIN CERTIFICATE-----/)
      expect(cert_str).not_to match(/-----BEGIN RSA PRIVATE KEY-----/)
    end
    it 'supports fetching only the cert even a second time' do
      cert_str = @trocla.password('mycert', 'x509', cert_options.merge('render' => {'certonly' => true }))
      expect(cert_str).to match(/-----BEGIN CERTIFICATE-----/)
      expect(cert_str).not_to match(/-----BEGIN RSA PRIVATE KEY-----/)
      cert_str = @trocla.password('mycert', 'x509', cert_options.merge('render' => {'certonly' => true }))
      expect(cert_str).to match(/-----BEGIN CERTIFICATE-----/)
      expect(cert_str).not_to match(/-----BEGIN RSA PRIVATE KEY-----/)
    end

    it 'does not simply increment the serial' do
      cert_str = @trocla.password('mycert', 'x509', cert_options)
      cert1 = OpenSSL::X509::Certificate.new(cert_str)
      cert_str = @trocla.password('mycert2', 'x509', cert_options)
      cert2 = OpenSSL::X509::Certificate.new(cert_str)

      expect(cert1.serial.to_i).not_to eq(1)
      expect(cert2.serial.to_i).not_to eq(2)
      expect((cert2.serial - cert1.serial).to_i).not_to eq(1)
    end

    it 'is able to get a cert signed by the ca that is again a ca' do
      cert_str = @trocla.password('mycert', 'x509', cert_options.merge({
        'become_ca' => true,
      }))
      cert = OpenSSL::X509::Certificate.new(cert_str)
      expect(cert.issuer.to_s).to eq(@ca.subject.to_s)
      expect((Date.parse(cert.not_after.localtime.to_s) - Date.today).to_i).to eq(365)
      expect(verify(@ca,cert)).to be true

      expect(cert.extensions.find{|e| e.oid == 'basicConstraints' }.value).to eq('CA:TRUE')
      ku = cert.extensions.find{|e| e.oid == 'keyUsage' }.value
      expect(ku).to match(/Certificate Sign/)
      expect(ku).to match(/CRL Sign/)
    end

    it 'supports simple name constraints for CAs' do
      ca2_str = @trocla.password('mycert_with_nc', 'x509', cert_options.merge({
        'name_constraints' => ['example.com','bla.example.net'],
        'become_ca' => true,
      }))
      ca2 = OpenSSL::X509::Certificate.new(ca2_str)
      expect(ca2.issuer.to_s).to eq(@ca.subject.to_s)
      expect((Date.parse(ca2.not_after.localtime.to_s) - Date.today).to_i).to eq(365)
      pending_for(:engine => 'jruby',:reason => 'NameConstraints verification seem to be broken in jRuby: https://github.com/jruby/jruby/issues/3502') do
        expect(verify(@ca,ca2)).to be true
      end

      expect(ca2.extensions.find{|e| e.oid == 'basicConstraints' }.value).to eq('CA:TRUE')
      ku = ca2.extensions.find{|e| e.oid == 'keyUsage' }.value
      expect(ku).to match(/Certificate Sign/)
      expect(ku).to match(/CRL Sign/)
      nc = ca2.extensions.find{|e| e.oid == 'nameConstraints' }.value
      pending_for(:engine => 'jruby',:reason => 'NameConstraints verification seem to be broken in jRuby: https://github.com/jruby/jruby/issues/3502') do
        expect(nc).to match(/Permitted:\n  DNS:example.com\n  DNS:bla.example.net/)
      end
      valid_cert_str = @trocla.password('myvalidexamplecert','x509', {
        'subject'  => '/C=ZZ/O=Trocla Inc./CN=foo.example.com/emailAddress=example@example.com',
        'ca' => 'mycert_with_nc'
      })
      valid_cert = OpenSSL::X509::Certificate.new(valid_cert_str)
      expect(valid_cert.issuer.to_s).to eq(ca2.subject.to_s)
      expect(verify([@ca,ca2],valid_cert)).to be true
      expect((Date.parse(valid_cert.not_after.localtime.to_s) - Date.today).to_i).to eq(365)

      false_cert_str = @trocla.password('myfalseexamplecert','x509', {
        'subject'  => '/C=ZZ/O=Trocla Inc./CN=foo.example.net/emailAddress=example@example.com',
        'ca' => 'mycert_with_nc'
      })

      false_cert = OpenSSL::X509::Certificate.new(false_cert_str)
      expect(false_cert.issuer.to_s).to eq(ca2.subject.to_s)
      expect(verify([@ca,ca2],false_cert)).to be false
      expect((Date.parse(false_cert.not_after.localtime.to_s) - Date.today).to_i).to eq(365)
    end

    it 'supports simple name constraints for CAs with leading dots' do
      ca2_str = @trocla.password('mycert_with_nc', 'x509', cert_options.merge({
        'name_constraints' => ['.example.com','.bla.example.net'],
        'become_ca' => true,
      }))
      ca2 = OpenSSL::X509::Certificate.new(ca2_str)
      expect(ca2.issuer.to_s).to eq(@ca.subject.to_s)
      expect((Date.parse(ca2.not_after.localtime.to_s) - Date.today).to_i).to eq(365)
      pending_for(:engine => 'jruby',:reason => 'NameConstraints verification seem to be broken in jRuby: https://github.com/jruby/jruby/issues/3502') do
        expect(verify(@ca,ca2)).to be true
      end

      expect(ca2.extensions.find{|e| e.oid == 'basicConstraints' }.value).to eq('CA:TRUE')
      ku = ca2.extensions.find{|e| e.oid == 'keyUsage' }.value
      expect(ku).to match(/Certificate Sign/)
      expect(ku).to match(/CRL Sign/)
      nc = ca2.extensions.find{|e| e.oid == 'nameConstraints' }.value
      expect(nc).to match(/Permitted:\n  DNS:.example.com\n  DNS:.bla.example.net/)
      valid_cert_str = @trocla.password('myvalidexamplecert','x509', {
        'subject'  => '/C=ZZ/O=Trocla Inc./CN=foo.example.com/emailAddress=example@example.com',
        'ca' => 'mycert_with_nc'
      })
      valid_cert = OpenSSL::X509::Certificate.new(valid_cert_str)
      expect(valid_cert.issuer.to_s).to eq(ca2.subject.to_s)
      expect((Date.parse(valid_cert.not_after.localtime.to_s) - Date.today).to_i).to eq(365)
      # workaround broken openssl
      if Gem::Version.new(%x{openssl version}.split(' ')[1]) < Gem::Version.new('1.0.2')
        skip_for(:engine => 'ruby',:reason => 'NameConstraints verification is broken on older openssl versions https://rt.openssl.org/Ticket/Display.html?id=3562') do
          expect(verify([@ca,ca2],valid_cert)).to be true
        end
      else
        expect(verify([@ca,ca2],valid_cert)).to be true
      end

      false_cert_str = @trocla.password('myfalseexamplecert','x509', {
        'subject'  => '/C=ZZ/O=Trocla Inc./CN=foo.example.net/emailAddress=example@example.com',
        'ca' => 'mycert_with_nc'
      })
      false_cert = OpenSSL::X509::Certificate.new(false_cert_str)
      expect(false_cert.issuer.to_s).to eq(ca2.subject.to_s)
      expect((Date.parse(false_cert.not_after.localtime.to_s) - Date.today).to_i).to eq(365)
      expect(verify([@ca,ca2],false_cert)).to be false
    end

    it 'is able to get a cert signed by the ca that is again a ca that is able to sign certs' do
      ca2_str = @trocla.password('mycert_and_ca', 'x509', cert_options.merge({
        'become_ca' => true,
      }))
      ca2 = OpenSSL::X509::Certificate.new(ca2_str)
      expect(ca2.issuer.to_s).to eq(@ca.subject.to_s)
      expect((Date.parse(ca2.not_after.localtime.to_s) - Date.today).to_i).to eq(365)
      expect(verify(@ca,ca2)).to be true

      cert2_str = @trocla.password('mycert', 'x509', {
        'ca'        => 'mycert_and_ca',
        'subject'   => '/C=ZZ/O=Trocla Inc./CN=test2/emailAddress=example@example.com',
        'become_ca' => true,
      })
      cert2 = OpenSSL::X509::Certificate.new(cert2_str)
      expect(cert2.issuer.to_s).to eq(ca2.subject.to_s)
      expect((Date.parse(cert2.not_after.localtime.to_s) - Date.today).to_i).to eq(365)
      skip_for(:engine => 'jruby',:reason => 'Chained CA validation seems to be broken on jruby atm.') do
        expect(verify([@ca,ca2],cert2)).to be true
      end
    end

    it 'respects all options' do
      co = cert_options.merge({
        'hash'         => 'sha1',
        'keysize'      => 2048,
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
      expect(cert.issuer.to_s).to eq(@ca.subject.to_s)
      ['C','ST','L','O','OU','CN'].each do |field|
        expect(cert.subject.to_s).to match(/#{field}=#{co[field]}/)
      end
      expect(cert.subject.to_s).to match(/(Email|emailAddress)=#{co['emailAddress']}/)
      hash_match = (defined?(RUBY_ENGINE) &&RUBY_ENGINE == 'jruby') ? 'RSA-SHA1' : 'sha1WithRSAEncryption'
      expect(cert.signature_algorithm).to eq(hash_match)
      expect(cert.not_before).to be < Time.now
      expect((Date.parse(cert.not_after.localtime.to_s) - Date.today).to_i).to eq(3650)
      # https://stackoverflow.com/questions/13747212/determine-key-size-from-public-key-pem-format
      expect(cert.public_key.n.num_bytes * 8).to eq(2048)
      expect(verify(@ca,cert)).to be true
      skip_for(:engine => 'jruby',:reason => 'subjectAltName represenation is broken in jruby-openssl -> https://github.com/jruby/jruby-openssl/pull/123') do
        expect(cert.extensions.find{|e| e.oid == 'subjectAltName' }.value).to eq('DNS:www.test, DNS:test, DNS:test1, DNS:test2, DNS:test3')
      end

      expect(cert.extensions.find{|e| e.oid == 'basicConstraints' }.value).to eq('CA:FALSE')
      ku = cert.extensions.find{|e| e.oid == 'keyUsage' }.value
      expect(ku).not_to match(/Certificate Sign/)
      expect(ku).not_to match(/CRL Sign/)
    end

    it 'shold not add subject alt name on empty array' do
      co = cert_options.merge({
        'CN'           => 'www.test',
        'altnames'     => []
      })
      cert_str = @trocla.password('mycert', 'x509', co)
      cert = OpenSSL::X509::Certificate.new(cert_str)
      expect(cert.issuer.to_s).to eq(@ca.subject.to_s)
      expect((Date.parse(cert.not_after.localtime.to_s) - Date.today).to_i).to eq(365)
      expect(verify(@ca,cert)).to be true
      expect(cert.extensions.find{|e| e.oid == 'subjectAltName' }).to be_nil
    end

    it 'prefers full subject of single subject parts' do
      co = cert_options.merge({
        'C'            => 'AA',
        'ST'           => 'Earth',
        'L'            => 'Here',
        'O'            => 'SSLTrocla',
        'OU'           => 'root',
        'CN'           => 'www.test',
        'emailAddress' => 'test@example.net',
      })
      cert_str = @trocla.password('mycert', 'x509', co)
      cert = OpenSSL::X509::Certificate.new(cert_str)
      ['C','ST','L','O','OU','CN'].each do |field|
        expect(cert.subject.to_s).not_to match(/#{field}=#{co[field]}/)
      end
      expect(cert.subject.to_s).not_to match(/(Email|emailAddress)=#{co['emailAddress']}/)
      expect((Date.parse(cert.not_after.localtime.to_s) - Date.today).to_i).to eq(365)
      expect(verify(@ca,cert)).to be true
    end
    it "is able to create a signed cert with custom keyUsage restrictions" do
      cert_str = @trocla.password('mycert_without_restrictions', 'x509', cert_options.merge({
        'CN'           => 'sign only test',
        'key_usages' => [ ],
      }))
      cert = OpenSSL::X509::Certificate.new(cert_str)
      # default size
      # https://stackoverflow.com/questions/13747212/determine-key-size-from-public-key-pem-format
      expect(cert.public_key.n.num_bytes * 8).to eq(4096)
      expect((Date.parse(cert.not_after.localtime.to_s) - Date.today).to_i).to eq(365)
      expect(cert.issuer.to_s).to eq(@ca.subject.to_s)
      expect(verify(@ca,cert)).to be true

      v = cert.extensions.find{|e| e.oid == 'basicConstraints' }.value
      expect(v).to_not eq('CA:TRUE')
      expect(cert.extensions.find{|e| e.oid == 'keyUsage' }).to be_nil
    end

  end
end
