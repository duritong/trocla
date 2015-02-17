class Trocla::Encryptions

  class Base
    attr_reader :trocla
    def initialize(trocla)
      @trocla = trocla
    end

    def encrypt(value)
      raise NoMethodError.new "#{self.class.name} needs to implement 'encrypt()'"
    end

    def decrypt(value)
      raise NoMethodError.new "#{self.class.name} needs to implement 'decrypt()'"
    end
  end

  class << self
    def [](enc)
      encryptions[enc.downcase]
    end

    def all
      Dir[ path '*' ].collect do |enc|
        File.basename(enc, '.rb').downcase
      end
    end

    def available?(encryption)
      all.include?(encryption.downcase)
    end

    private
    def encryptions
      @@encryptions ||= Hash.new do |hash, encryption|
        encryption = encryption.downcase
        if File.exists?( path encryption )
          require "trocla/encryptions/#{encryption}"
          class_name = "Trocla::Encryptions::#{encryption.capitalize}"
          hash[encryption] = (eval class_name)
        else
          raise "Encryption #{encryption} is not supported!"
        end
      end
    end

    def path(encryption)
      File.expand_path(
        File.join(File.dirname(__FILE__), 'encryptions', "#{encryption}.rb")
      )
    end
  end
end
