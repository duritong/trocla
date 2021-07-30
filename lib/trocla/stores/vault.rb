# the default vault based store
class Trocla::Stores::Vault < Trocla::Store
  attr_reader :vault, :mount
  def initialize(config,trocla)
    super(config,trocla)
    require 'vault'
    @mount = (config.delete(:mount) || 'kv')
    # load expire support by default
    @vault = Vault::Client.new(config)
  end

  def close
  end

  def get(key,format)
    read(key)[format.to_sym]
  end

  def formats(key)
    read(key).keys
  end

  def search(key)
    vault.kv(mount).list(key)
  end

  private
  def read(key)
    k = vault.kv(mount).read(key)
    k.nil? ? {} : k.data
  end

  def write(key, value)
    vault.kv(mount).write(key, value)
  end

  def set_plain(key,value,options)
    set_format(key,'plain',value,options)
  end

  def set_format(key,format,value,options)
    write(key, read(key).merge({format.to_sym => value}))
  end

  def delete_all(key)
    vault.kv(mount).delete(key)
  end

  def delete_format(key,format)
    old = read(key)
    write(key, old.reject { |k,v| k == format.to_sym })
    old[format.to_sym]
  end
end
