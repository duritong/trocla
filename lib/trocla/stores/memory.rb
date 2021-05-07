# a simple in memory store just as an example
class Trocla::Stores::Memory < Trocla::Store
  attr_reader :memory
  def initialize(config,trocla)
    super(config,trocla)
    @memory = Hash.new({})
  end

  def get(key,format)
    unless expired?(key)
      memory[key][format]
    else
      delete_all(key)
      nil
    end
  end
  def set(key,format,value,options={})
    super(key,format,value,options)
    set_expires(key,options['expires'])
  end

  def formats(key)
    memory[key].empty? ? nil : memory[key].keys
  end

  def search(key)
    r = memory.keys.grep(/#{key}/)
    r.empty? ? nil : r
  end

  private
  def set_plain(key,value,options)
    memory[key] = { 'plain' => value }
  end

  def set_format(key,format,value,options)
    memory[key].merge!({ format => value })
  end

  def delete_all(key)
    memory.delete(key)
  end
  def delete_format(key,format)
    old_val = (h = memory[key]).delete(format)
    h.empty? ? memory.delete(key) : memory[key] = h
    set_expires(key,nil)
    old_val
  end
  private
  def set_expires(key,expires)
    expires = memory[key]['_expires'] if expires.nil?
    if expires && expires > 0
      memory[key]['_expires'] = expires
      memory[key]['_expires_at'] = Time.now + expires
    else
      memory[key].delete('_expires')
      memory[key].delete('_expires_at')
    end
  end
  def expired?(key)
    memory.key?(key) &&
      (a = memory[key]['_expires_at']).is_a?(Time) && \
      (a < Time.now)
  end
end
