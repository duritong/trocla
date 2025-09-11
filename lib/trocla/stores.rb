require 'trocla/store'
# store management
class Trocla::Stores
  class << self
    def [](store)
      stores[store.to_s.downcase]
    end

    def all
      @all ||= Dir[path '*'].collect do |store|
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
        if File.exist?(path(store))
          require "trocla/stores/#{store}"
          # Handle compound names like vault_jwt -> VaultJwt
          class_name = "Trocla::Stores::#{store.split('_').map(&:capitalize).join}"
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
