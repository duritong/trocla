# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'


require 'jeweler'
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
require 'trocla'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "trocla"
  gem.homepage = "http://www.puzzle.ch"
  gem.license = "GPLv3"
  gem.summary = "Trocla a simple password generator and storage" 
  gem.description = "Trocla helps you to generate random passwords and to store them in various formats (plain, MD5, bcrypt) for later retrival."
  gem.email = "mh+trocla@immerda.ch"
  gem.authors = ["mh"]
  gem.version = Trocla::VERSION::STRING
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :default => :spec

gem 'rdoc'
require 'rdoc/task'
RDoc::Task.new do |rdoc|
  version = Trocla::VERSION::STRING
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "trocla #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
