# frozen_string_literal: true

# Trocla::Encryptions
class Trocla::Encryptions
  # Base
  class Base
    attr_reader :trocla, :config

    def initialize(config, trocla)
      @trocla = trocla
      @config = config
    end

    def encrypt(_)
      raise NoMethodError.new("#{self.class.name} needs to implement 'encrypt()'")

    end

    def decrypt(_)
      raise NoMethodError.new("#{self.class.name} needs to implement 'decrypt()'")

    end
  end

  class << self
    def [](enc)
      encryptions[enc.to_s.downcase]
    end

    def all
      Dir[path '*'].collect do |enc|
        File.basename(enc, '.rb').downcase
      end
    end

    def available?(encryption)
      all.include?(encryption.to_s.downcase)
    end

    private

    def encryptions
      @@encryptions ||= Hash.new do |hash, encryption|
        encryption = encryption.to_s.downcase
        if File.exist?(path encryption)
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
