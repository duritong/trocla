# a simple in memory store just as an example
class Trocla::Stores::Memory < Trocla::Store
  attr_reader :memory
  def initialize(config,trocla)
    super(config,trocla)
    @memory = Hash.new({})
  end

  def get(key,format)
    memory[key][format]
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
    old_val
  end
end
