class Trocla::Formats::Yescrypt < Trocla::Formats::Base
  expensive true
  require 'xcrypt' unless Object.const_defined?(:RUBY_ENGINE) and RUBY_ENGINE == 'jruby'
  def format(plain_password, options = {})
    raise 'Not supported on Jruby' if Object.const_defined?(:RUBY_ENGINE) and RUBY_ENGINE == 'jruby'
    raise "Unsupported cost factor" if options['cost'] && options['cost'] > 11
    XCrypt.yescrypt(plain_password, cost: options['cost'])
  end
end
