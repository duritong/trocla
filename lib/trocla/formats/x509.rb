class Trocla::Formats::X509
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
    sign_with = options['ca'] || nil
    keysize = options['keysize'] || 2048
    serial = options['serial'] || 1
    days = options['days'] || 365
    altnames = options['altnames'] || nil
    altnames.collect { |v| "DNS:#{v}" }.join(', ') if altnames

    # nice help: https://gist.github.com/mitfik/1922961

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
      cert.add_extension ef.create_extension("basicConstraints","CA:TRUE", true) if subject == issuer
      cert.add_extension ef.create_extension("basicConstraints","CA:FALSE", true) if subject != issuer
      cert.add_extension ef.create_extension("keyUsage", "nonRepudiation, digitalSignature, keyEncipherment", true)
      cert.add_extension ef.create_extension("subjectAltName", altnames, true) if altnames
      cert.add_extension ef.create_extension("authorityKeyIdentifier", "keyid:always,issuer:always")

      cert
    end

    def getca(ca)
      subreq = Trocla.new
      subreq.get_password(ca,'x509')
    end

    def getserial(ca,serial)
      subreq = Trocla.new
      newser = subreq.get_password("#{ca}_serial",'plain')
      if newser
        newser + 1
      else
        serial
      end
    end

    def setserial(ca,serial)
      subreq = Trocla.new
      subreq.set_password("#{ca}_serial",'plain',serial)
    end

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
        request.sign(key, OpenSSL::Digest::SHA1.new)
      rescue Exception => e
        raise "Certificate request #{subject} creation failed: #{e.message}"
      end

      begin
        csr_cert = mkcert(caserial, request.subject, ca, request.public_key, days, altnames)
        csr_cert.sign(cakey, OpenSSL::Digest::SHA1.new)
        setserial(sign_with, caserial)
      rescue Exception => e
        raise "Certificate #{subject} signing failed: #{e.message}"
      end

      key.send("to_pem") + csr_cert.send("to_pem")
    else # self-signed certificate
      begin
        subj = OpenSSL::X509::Name.parse(subject)
        cert = mkcert(serial, subj, nil, key.public_key, days, altnames)
        cert.sign(key, OpenSSL::Digest::SHA1.new)
      rescue Exception => e
        raise "Self-signed certificate #{subject} creation failed: #{e.message}"
      end

      key.send("to_pem") + cert.send("to_pem")
    end
  end
end
