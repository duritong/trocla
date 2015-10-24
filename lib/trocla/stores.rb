require 'trocla/store'
# store management
class Trocla::Stores
  class << self
    def [](store)
      stores[store.to_s.downcase]
    end

    def all
      @all ||= Dir[ path '*' ].collect do |store|
        File.basename(store, '.rb').downcase
      end
    end

    def available?(store)
      all.include?(store.to_s.downcase)
    end

    private
    def stores
      @@stores ||= Hash.new do |hash, store|
        store = store.to_s.downcase
        if File.exists?(path(store))
          require "trocla/stores/#{store}"
          class_name = "Trocla::Stores::#{store.capitalize}"
          hash[store] = (eval class_name)
        else
          raise "Store #{store} is not supported!"
        end
      end
    end

    def path(store)
      File.expand_path(
        File.join(File.dirname(__FILE__), 'stores', "#{store}.rb")
      )
    end
  end
end
