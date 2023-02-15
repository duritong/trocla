# the default vault based store
class Trocla::Stores::Vault < Trocla::Store
  attr_reader :vault, :mount, :destroy

  def initialize(config, trocla)
    super(config, trocla)
    require 'vault'
    @mount = (config.delete(:mount) || 'kv')
    @destroy = (config.delete(:destroy) || false)
    # load expire support by default
    @vault = Vault::Client.new(config)
  end

  def close; end

  def get(key, format)
    read(key)[format.to_sym]
  end

  def formats(key)
    read(key).keys
  end

  def search(key)
    arr = key.split('/')
    regexp = Regexp.new(arr.pop(1)[0].to_s)
    path = arr.join('/')
    list = vault.kv(mount).list(path)
    list.map! do |l|
      if regexp.match(l)
        path.empty? ? l : [path, l].join('/')
      end
    end
    list.compact
  end

  private

  def read(key)
    k = vault.kv(mount).read(key)
    k.nil? ? {} : k.data
  end

  def write(key, value, options = {})
    vault.kv(mount).write_metadata(key, convert_metadata(options)) unless options.empty?
    vault.kv(mount).write(key, value)
  end

  def set_plain(key, value, options)
    set_format(key, 'plain', value, options)
  end

  def set_format(key, format, value, options)
    write(
      key,
      read(key).merge({ format.to_sym => value }),
      options
    )
  end

  def delete_all(key)
    destroy ? vault.kv(mount).destroy(key) : vault.kv(mount).delete(key)
  end

  def delete_format(key, format)
    old = read(key)
    new = old.reject { |k, _| k == format.to_sym }
    new.empty? ? delete_all(key) : write(key, new)
    old[format.to_sym]
  end

  def convert_metadata(metadatas)
    metadatas.transform_keys!(&:to_sym)
    metadatas[:delete_version_after] = metadatas.delete(:expires) if metadatas[:expires]
    %i[random profiles expires length].each { |k| metadatas.delete(k) }
    metadatas
  end
end
