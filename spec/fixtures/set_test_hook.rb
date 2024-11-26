class Trocla
  module Hooks

    def self.set_test_hook(trocla, key, format, options)
      self.set_messages << "#{key}_#{format}"
    end

    def self.set_messages
      @set_messages ||= []
    end
  end
end
