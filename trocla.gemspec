# frozen_string_literal: true

require_relative "lib/trocla/version"

Gem::Specification.new do |spec|
  spec.name          = "trocla"
  spec.version       = Trocla::VERSION::STRING
  spec.authors       = ["mh"]
  spec.email         = ["mh+trocla@immerda.ch"]

  spec.summary       = "Trocla a simple password generator and storage"
  spec.description   = "Trocla helps you to generate random passwords and to store them in various formats (plain, MD5, bcrypt) for later retrieval."
  spec.homepage      = "https://tech.immerda.ch/2011/12/trocla-get-hashed-passwords-out-of-puppet-manifests/"
  spec.license       = "GPL-3.0-or-later"
  spec.required_ruby_version = ">= 3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/duritong/trocla"
  spec.metadata["changelog_uri"] = "https://github.com/duritong/trocla/blob/master/CHANGELOG.md"

  spec.files         = Dir.glob("{bin,lib}/**/*") + %w[LICENSE.txt README.md CHANGELOG.md]
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{\Abin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "highline", "~> 3.1"
  spec.add_dependency "moneta", "~> 1.6"
  spec.add_dependency "bcrypt", "~> 3.1"
  spec.add_dependency "sshkey", "~> 3.0"
  spec.add_dependency "base64", "~> 0.3.0"
  spec.add_dependency "pstore", "~> 0.2"
  spec.add_dependency "argon2", "~> 2.3"
  spec.add_dependency "xcrypt", "~> 0.2"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.13"
  spec.add_development_dependency "rspec-pending_for", "~> 0.1"
  spec.add_development_dependency "rdoc", "~> 7.0"
end
