source "http://rubygems.org"
# Add dependencies required to use your gem here.
# Example:
#   gem "activesupport", ">= 2.3.5"

if RUBY_VERSION.to_f > 1.8
  gem "moneta"
  gem "highline"
else
  gem "moneta", "~> 0.7.20"
  gem "highline", "~> 1.6.2"
  gem 'rake', '< 11'
end

if defined?(RUBY_ENGINE) && (RUBY_ENGINE == 'jruby')
  gem 'jruby-openssl'
end
gem "bcrypt"

# Add dependencies to develop your gem here.
# Include everything needed to run rake, tests, features, etc.
group :development do
  if RUBY_VERSION.to_f > 1.8
    gem "rspec"
    gem "rdoc"
    gem "jeweler"
  else
    gem "rspec", "~> 2.4"
    gem "rdoc", "~> 3.8"
    gem "jeweler", "~> 1.6"
    gem "addressable", "~> 2.3.8"
  end
  gem 'rspec-pending_for'
end
