require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

require 'trocla/stores/moneta'
describe Trocla::Stores::Moneta do
  include_examples 'store_validation', Trocla::Stores::Moneta.new({'adapter' => :Memory},{:expires => true})
end
