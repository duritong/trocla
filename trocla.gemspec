# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-
# stub: trocla 0.6.0 ruby lib

Gem::Specification.new do |s|
  s.name = "trocla".freeze
  s.version = "0.6.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["mh".freeze]
  s.date = "2024-12-30"
  s.description = "Trocla helps you to generate random passwords and to store them in various formats (plain, MD5, bcrypt) for later retrival.".freeze
  s.email = "mh+trocla@immerda.ch".freeze
  s.executables = ["trocla".freeze]
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.md"
  ]
  s.files = [
    ".document",
    ".github/workflows/ruby.yml",
    ".rspec",
    "CHANGELOG.md",
    "Gemfile",
    "LICENSE.txt",
    "README.md",
    "Rakefile",
    "bin/trocla",
    "ext/redhat/rubygem-trocla.spec",
    "lib/VERSION",
    "lib/trocla.rb",
    "lib/trocla/default_config.yaml",
    "lib/trocla/encryptions.rb",
    "lib/trocla/encryptions/none.rb",
    "lib/trocla/encryptions/ssl.rb",
    "lib/trocla/formats.rb",
    "lib/trocla/formats/bcrypt.rb",
    "lib/trocla/formats/md5crypt.rb",
    "lib/trocla/formats/mysql.rb",
    "lib/trocla/formats/pgsql.rb",
    "lib/trocla/formats/plain.rb",
    "lib/trocla/formats/sha1.rb",
    "lib/trocla/formats/sha256crypt.rb",
    "lib/trocla/formats/sha512crypt.rb",
    "lib/trocla/formats/ssha.rb",
    "lib/trocla/formats/sshkey.rb",
    "lib/trocla/formats/wireguard.rb",
    "lib/trocla/formats/x509.rb",
    "lib/trocla/hooks.rb",
    "lib/trocla/store.rb",
    "lib/trocla/stores.rb",
    "lib/trocla/stores/memory.rb",
    "lib/trocla/stores/moneta.rb",
    "lib/trocla/stores/vault.rb",
    "lib/trocla/util.rb",
    "lib/trocla/version.rb",
    "spec/data/.keep",
    "spec/fixtures/delete_test_hook.rb",
    "spec/fixtures/set_test_hook.rb",
    "spec/spec_helper.rb",
    "spec/trocla/encryptions/none_spec.rb",
    "spec/trocla/encryptions/ssl_spec.rb",
    "spec/trocla/formats/pgsql_spec.rb",
    "spec/trocla/formats/sshkey_spec.rb",
    "spec/trocla/formats/x509_spec.rb",
    "spec/trocla/hooks_spec.rb",
    "spec/trocla/store/memory_spec.rb",
    "spec/trocla/store/moneta_spec.rb",
    "spec/trocla/util_spec.rb",
    "spec/trocla_spec.rb",
    "trocla.gemspec"
  ]
  s.homepage = "https://tech.immerda.ch/2011/12/trocla-get-hashed-passwords-out-of-puppet-manifests/".freeze
  s.licenses = ["GPLv3".freeze]
  s.rubygems_version = "3.5.22".freeze
  s.summary = "Trocla a simple password generator and storage".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<highline>.freeze, ["~> 2.0.0".freeze])
  s.add_runtime_dependency(%q<moneta>.freeze, ["~> 1.0".freeze])
  s.add_runtime_dependency(%q<bcrypt>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<sshkey>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<addressable>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<jeweler>.freeze, ["~> 2.0".freeze])
  s.add_development_dependency(%q<rdoc>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec-pending_for>.freeze, [">= 0".freeze])
end

