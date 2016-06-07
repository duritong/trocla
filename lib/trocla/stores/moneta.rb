# the default moneta based store
class Trocla::Stores::Moneta < Trocla::Store
  attr_reader :moneta
  def initialize(config,trocla)
    super(config,trocla)
    require 'moneta'
    # load expire support by default
    adapter_options = { :expires => true }.merge(
                          store_config['adapter_options']||{})
    @moneta = Moneta.new(store_config['adapter'],adapter_options)
  end

  def close
    moneta.close
  end

  def get(key,format)
    moneta.fetch(key, {})[format]
  end

  private
  def set_plain(key,value,options)
    h = { 'plain' => value }
    mo = moneta_options(key,options)
    if options['expires'] && options['expires'] > 0
      h['_expires'] = options['expires']
    else
      # be sure that we disable the existing
      # expires if nothing is set.
      mo[:expires] = false
    end
    moneta.store(key,h,mo)
  end

  def set_format(key,format,value,options)
    moneta.store(key,
                 moneta.fetch(key,{}).merge({ format => value }),
                 moneta_options(key,options))
  end

  def delete_all(key)
    moneta.delete(key)
  end
  def delete_format(key,format)
    old_val = (h = moneta.fetch(key,{})).delete(format)
    h.empty? ? moneta.delete(key) : moneta.store(key,h,moneta_options(key,{}))
    old_val
  end
  def moneta_options(key,options)
    res = {}
    if options.key?('expires')
      res[:expires] = options['expires']
    elsif e = moneta.fetch(key, {})['_expires']
      res[:expires] = e
    end
    res
  end
end
