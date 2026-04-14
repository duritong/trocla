class Trocla::Formats::Yescrypt < Trocla::Formats::Base
  expensive true
  require 'xcrypt'
  def format(plain_password, options = {})
    raise "Unsupported cost factor" if options['cost'] && options['cost'] > 11
    XCrypt.yescrypt(plain_password, cost: options['cost'])
  end
end
