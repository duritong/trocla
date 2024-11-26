class Trocla
  module Hooks

    def self.delete_test_hook(trocla, key, format, options)
      self.delete_messages << "#{key}_#{format}"
    end

    def self.delete_messages
      @delete_messages ||= []
    end
  end
end
