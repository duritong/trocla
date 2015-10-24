# the default moneta based store
class Trocla::Stores::Moneta < Trocla::Store
  attr_reader :moneta
  def initialize(config,trocla)
    super(config,trocla)
    require 'moneta'
    @moneta = Moneta.new(store_config['adapter'],
                         store_config['adapter_options']||{})
  end

  def get(key,format)
    moneta.fetch(key, {})[format]
  end

  private
  def set_plain(key,value,options)
    moneta[key] = { 'plain' => value }
  end

  def set_format(key,format,value,options)
    moneta[key] = moneta.fetch(key,{}).merge({ format => value })
  end

  def delete_all(key)
    moneta.delete(key)
  end
  def delete_format(key,format)
    old_val = (h = moneta.fetch(key,{})).delete(format)
    h.empty? ? moneta.delete(key) : moneta[key] = h
    old_val
  end
end
