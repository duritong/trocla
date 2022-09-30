# frozen_string_literal: true

# Trocla::Formats
class Trocla::Formats
  # Base
  class Base
    attr_reader :trocla

    def initialize(trocla)
      @trocla = trocla
    end

    def render(output, render_options = {})
      output
    end

    def expensive?
      self.class.expensive?
    end
    class << self
      def expensive(is_expensive)
        @expensive = is_expensive
      end

      def expensive?
        @expensive == true
      end
    end
  end

  class << self
    def [](format)
      formats[format.downcase]
    end

    def all
      Dir[File.expand_path(
        File.join(File.dirname(__FILE__), 'formats', '*.rb')
      )].collect { |f| File.basename(f, '.rb').downcase }
    end

    def available?(format)
      all.include?(format.downcase)
    end

    private

    def formats
      @@formats ||= Hash.new do |hash, format|
        format = format.downcase
        if File.exist?(path(format))
          require "trocla/formats/#{format}"
          hash[format] = (eval "Trocla::Formats::#{format.capitalize}")
        else
          raise "Format #{format} is not supported!"
        end
      end
    end

    def path(format)
      File.expand_path(File.join(File.dirname(__FILE__), 'formats', "#{format}.rb"))
    end
  end
end
