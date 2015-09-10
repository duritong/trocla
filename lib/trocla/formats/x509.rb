class Trocla::Formats::X509 < Trocla::Formats::Base
  require 'openssl'
  def format(plain_password,options={})

    if plain_password.match(/-----BEGIN RSA PRIVATE KEY-----.*-----END RSA PRIVATE KEY-----.*-----BEGIN CERTIFICATE-----.*-----END CERTIFICATE-----/m)
      # just an import, don't generate any new keys
      return plain_password
    end

    if options['subject']
      subject = options['subject']
    elsif options['CN']
      subject = ''
      ['C','ST','L','O','OU','CN','emailAddress'].each do |field|
        subject << "/#{field}=#{options[field]}" if options[field]
      end
    else
      raise "You need to pass \"subject\" or \"CN\" as an option to use this format"
    end
    hash = options['hash'] || 'sha2'
    sign_with = options['ca'] || nil
    keysize = options['keysize'] || 2048
    serial = options['serial'] || 1
    days = options['days'].to_i || 365
    altnames = options['altnames'] || nil
    altnames.collect { |v| "DNS:#{v}" }.join(', ') if altnames

    begin
      key = mkkey(keysize)
    rescue Exception => e
      raise "Private key for #{subject} creation failed: #{e.message}"
    end

    if sign_with # certificate signed with CA
      begin
        ca = OpenSSL::X509::Certificate.new(getca(sign_with))
        cakey = OpenSSL::PKey::RSA.new(getca(sign_with))
        caserial = getserial(sign_with, serial)
      rescue Exception => e
        raise "Value of #{sign_with} can't be loaded as CA: #{e.message}"
      end

      begin
        subj = OpenSSL::X509::Name.parse(subject)
        request = mkreq(subj, key.public_key)
        request.sign(key, signature(hash))
      rescue Exception => e
        raise "Certificate request #{subject} creation failed: #{e.message}"
      end

      begin
        csr_cert = mkcert(caserial, request.subject, ca, request.public_key, days, altnames)
        csr_cert.sign(cakey, signature(hash))
        setserial(sign_with, caserial)
      rescue Exception => e
        raise "Certificate #{subject} signing failed: #{e.message}"
      end

      key.send("to_pem") + csr_cert.send("to_pem")
    else # self-signed certificate
      begin
        subj = OpenSSL::X509::Name.parse(subject)
        cert = mkcert(serial, subj, nil, key.public_key, days, altnames)
        cert.sign(key, signature(hash))
      rescue Exception => e
        raise "Self-signed certificate #{subject} creation failed: #{e.message}"
      end

      key.send("to_pem") + cert.send("to_pem")
    end
  end
  private

  # nice help: https://gist.github.com/mitfik/1922961

  def signature(hash = 'sha2')
    if hash == 'sha1'
        OpenSSL::Digest::SHA1.new
    elsif hash == 'sha224'
        OpenSSL::Digest::SHA224.new
    elsif hash == 'sha2' || hash == 'sha256'
        OpenSSL::Digest::SHA256.new
    elsif hash == 'sha384'
        OpenSSL::Digest::SHA384.new
    elsif hash == 'sha512'
        OpenSSL::Digest::SHA512.new
    else
        raise "Unrecognized hash: #{hash}"
    end
  end

  def mkkey(len)
    OpenSSL::PKey::RSA.generate(len)
  end

  def mkreq(subject,public_key)
    request = OpenSSL::X509::Request.new
    request.version = 0
    request.subject = subject
    request.public_key = public_key

    request
  end

  def mkcert(serial,subject,issuer,public_key,days,altnames)
    cert = OpenSSL::X509::Certificate.new
    issuer = cert if issuer == nil
    cert.subject = subject
    cert.issuer = issuer.subject
    cert.not_before = Time.now
    cert.not_after = Time.now + days * 24 * 60 * 60
    cert.public_key = public_key
    cert.serial = serial
    cert.version = 2

    ef = OpenSSL::X509::ExtensionFactory.new
    ef.subject_certificate = cert
    ef.issuer_certificate = issuer
    cert.extensions = [ ef.create_extension("subjectKeyIdentifier", "hash") ]
    cert.add_extension ef.create_extension("basicConstraints","CA:TRUE", true) if cert.subject == cert.issuer
    cert.add_extension ef.create_extension("basicConstraints","CA:FALSE", true) if cert.subject != cert.issuer
    cert.add_extension ef.create_extension("keyUsage", "keyCertSign, cRLSign, nonRepudiation, digitalSignature, keyEncipherment", true) if cert.subject == cert.issuer
    cert.add_extension ef.create_extension("keyUsage", "nonRepudiation, digitalSignature, keyEncipherment", true) if cert.subject != cert.issuer
    cert.add_extension ef.create_extension("subjectAltName", altnames, true) if altnames
    cert.add_extension ef.create_extension("authorityKeyIdentifier", "keyid:always,issuer:always")

    cert
  end

  def getca(ca)
    trocla.get_password(ca,'x509')
  end

  def getserial(ca,serial)
    newser = trocla.get_password("#{ca}_serial",'plain')
    if newser
      newser + 1
    else
      serial
    end
  end

  def setserial(ca,serial)
    trocla.set_password("#{ca}_serial",'plain',serial)
  end
end
