# implements the default store behavior
class Trocla::Store
  attr_reader :store_config, :trocla
  def initialize(config,trocla)
    @store_config = config
    @trocla = trocla
  end

  # closes the store
  # when called do whatever "closes" your
  # store, e.g. close database connections.
  def close
  end

  # should return value for key & format
  # returns nil if nothing or a nil value
  # was found.
  # If a key is expired it must return nil.
  def get(key,format)
    raise 'not implemented'
  end

  # sets value for key & format
  # setting the plain format must invalidate
  # all other formats as they should either
  # be derived from plain or set directly.
  # options is a hash containing further
  # information for the store. e.g. expiration
  # of a key. Keys can have an expiration /
  # timeout by setting `expires` within
  # the options hashs. Value of `expires`
  # must be an integer indicating the
  # amount of seconds a key can live with.
  # This mechanism is expected to be
  # be implemented by the backend.
  def set(key,format,value,options={})
    if format == 'plain'
      set_plain(key,value,options)
    else
      set_format(key,format,value,options)
    end
  end

  # deletes the value for format
  # if format is nil everything is deleted
  # returns value of format or hash of
  # format => value # if everything is
  # deleted.
  def delete(key,format=nil)
    format.nil? ? (delete_all(key)||{}) : delete_format(key,format)
  end

  private
  # sets a new plain value
  # *must* invalidate all
  # other formats
  def set_plain(key,value,options)
    raise 'not implemented'
  end

  # sets a value of a format
  def set_format(key,format,value,options)
    raise 'not implemented'
  end

  # deletes all entries of this key
  # and returns a hash with all
  # formats and values
  # or nil if nothing is found
  def delete_all(key)
    raise 'not implemented'
  end

  # deletes the value of the passed
  # key & format and returns the
  # value.
  def delete_format(key,format)
    raise 'not implemented'
  end
end
