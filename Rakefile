# frozen_string_literal: true

require 'bundler/setup' rescue LoadError
require 'rspec/core/rake_task'
require 'rdoc/task'
require_relative 'lib/trocla/version'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = 'spec/**/*_spec.rb'
end

task default: :spec

RDoc::Task.new do |rdoc|
  version = Trocla::VERSION::STRING
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "trocla #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc 'Run tests'
task :test => :spec
