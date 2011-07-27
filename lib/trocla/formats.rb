class Trocla::Formats
  class << self
    def [](format)
      formats[format.downcase]
    end
    
    def all
      Dir[File.expand_path(File.join(File.dirname(__FILE__),'formats','*.rb'))].collect{|f| File.basename(f,'.rb').downcase }
    end
    
    def available?(format)
      all.include?(format.downcase)
    end
    
    private
    def formats
      @@formats ||= Hash.new do |hash, format|
        format = format.downcase
        if File.exists?(path(format))
          require "trocla/formats/#{format}"
          hash[format] = (eval "Trocla::Formats::#{format.capitalize}").new
        else
          raise "Format #{format} is not supported!"
        end
      end
    end
    
    def path(format)
      File.expand_path(File.join(File.dirname(__FILE__),'formats',"#{format}.rb"))
    end
  end
end