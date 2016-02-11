require 'openssl'
class Trocla::Formats::X509 < Trocla::Formats::Base
  def format(plain_password,options={})

    if plain_password.match(/-----BEGIN RSA PRIVATE KEY-----.*-----END RSA PRIVATE KEY-----.*-----BEGIN CERTIFICATE-----.*-----END CERTIFICATE-----/m)
      # just an import, don't generate any new keys
      return plain_password
    end

    cn = nil
    if options['subject']
      subject = options['subject']
      if cna = OpenSSL::X509::Name.parse(subject).to_a.find{|e| e[0] == 'CN' }
        cn = cna[1]
      end
    elsif options['CN']
      subject = ''
      cn = options['CN']
      ['C','ST','L','O','OU','CN','emailAddress'].each do |field|
        subject << "/#{field}=#{options[field]}" if options[field]
      end
    else
      raise "You need to pass \"subject\" or \"CN\" as an option to use this format"
    end
    hash = options['hash'] || 'sha2'
    sign_with = options['ca']
    become_ca = options['become_ca'] || false
    keysize = options['keysize'] || 4096
    days = options['days'].nil? ? 365 : options['days'].to_i
    name_constraints = Array(options['name_constraints'])
    key_usages = options['key_usages']
    key_usages = Array(key_usages) if key_usages

    altnames = if become_ca || (an = options['altnames']) && Array(an).empty?
      []
    else
      # ensure that we have the CN with us, but only if it
      # it's like a hostname.
      # This might have to be improved.
      if cn.include?(' ')
        Array(an).collect { |v| "DNS:#{v}" }.join(', ')
      else
        (["DNS:#{cn}"] + Array(an).collect { |v| "DNS:#{v}" }).uniq.join(', ')
      end
    end

    begin
      key = mkkey(keysize)
    rescue Exception => e
      puts e.backtrace
      raise "Private key for #{subject} creation failed: #{e.message}"
    end

    cert = nil
    if sign_with # certificate signed with CA
      begin
        ca_str = trocla.get_password(sign_with,'x509')
        ca = OpenSSL::X509::Certificate.new(ca_str)
        cakey = OpenSSL::PKey::RSA.new(ca_str)
        caserial = getserial(sign_with)
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
        cert = mkcert(caserial, request.subject, ca, request.public_key, days,
                        altnames, key_usages, name_constraints, become_ca)
        cert.sign(cakey, signature(hash))
        addserial(sign_with, caserial)
      rescue Exception => e
        raise "Certificate #{subject} signing failed: #{e.message}"
      end
    else # self-signed certificate
      begin
        subj = OpenSSL::X509::Name.parse(subject)
        cert = mkcert(getserial(subj), subj, nil, key.public_key, days,
                        altnames, key_usages, name_constraints, become_ca)
        cert.sign(key, signature(hash))
      rescue Exception => e
        raise "Self-signed certificate #{subject} creation failed: #{e.message}"
      end
    end
    key.to_pem + cert.to_pem
  end

  def render(output,render_options={})
    if render_options['keyonly']
      OpenSSL::PKey::RSA.new(output).to_pem
    elsif render_options['certonly']
      OpenSSL::X509::Certificate.new(output).to_pem
    else
      super(output,render_options)
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
    request.subject = subject
    request.public_key = public_key

    request
  end

  def mkcert(serial,subject,issuer,public_key,days,altnames, key_usages = nil, name_constraints = [], become_ca = false)
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

    if become_ca
      cert.add_extension ef.create_extension("basicConstraints","CA:TRUE", true)
      unless (ku = key_usages || ca_key_usages).empty?
        cert.add_extension ef.create_extension("keyUsage", ku.join(', '), true)
      end
      if name_constraints && !name_constraints.empty?
        cert.add_extension ef.create_extension("nameConstraints","permitted;DNS:#{name_constraints.join(',permitted;DNS:')}",true)
      end
    else
      cert.add_extension ef.create_extension("subjectAltName", altnames, true) unless altnames.empty?
      cert.add_extension ef.create_extension("basicConstraints","CA:FALSE", true)
      unless (ku = key_usages || cert_key_usages).empty?
        cert.add_extension ef.create_extension("keyUsage", ku.join(', '), true)
      end
    end
    cert.add_extension ef.create_extension("authorityKeyIdentifier", "keyid:always,issuer:always")

    cert
  end

  def getserial(ca)
    newser = Trocla::Util.random_str(20,'hexadecimal').to_i(16)
    all_serials(ca).include?(newser) ? getserial(ca) : newser
  end

  def all_serials(ca)
    if allser = trocla.get_password("#{ca}_all_serials",'plain')
      YAML.load(allser)
    else
      []
    end
  end

  def addserial(ca,serial)
    serials = all_serials(ca) << serial
    trocla.set_password("#{ca}_all_serials",'plain',YAML.dump(serials))
  end

  def cert_key_usages
    ['nonRepudiation', 'digitalSignature', 'keyEncipherment']
  end
  def ca_key_usages
    ['keyCertSign', 'cRLSign', 'nonRepudiation',
      'digitalSignature', 'keyEncipherment' ]
  end
end
