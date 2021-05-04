source "http://rubygems.org"
# Add dependencies required to use your gem here.
# Example:
#   gem "activesupport", ">= 2.3.5"

gem "moneta", "~> 1.4.0"
gem "highline", "~> 2.0.0"

if defined?(RUBY_ENGINE) && (RUBY_ENGINE == 'jruby')
  gem 'jruby-openssl'
end
gem "bcrypt"

# Add dependencies to develop your gem here.
# Include everything needed to run rake, tests, features, etc.
group :development do
  gem "rspec"
  gem "rdoc"
  gem "jeweler"
  gem "addressable"
  gem 'rspec-pending_for'
end
