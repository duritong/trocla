require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

require 'trocla/stores/memory'
describe Trocla::Stores::Memory do
  include_examples 'store_validation', Trocla::Stores::Memory.new({},nil)
end
