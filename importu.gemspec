# frozen_string_literal: true
$LOAD_PATH.unshift File.expand_path("lib", __dir__)
require "importu/version"

Gem::Specification.new do |s|
  s.name        = "importu"
  s.version     = Importu::VERSION
  s.platform    = Gem::Platform::RUBY
  s.required_ruby_version = ">= 3.1"
  s.authors     = ["Daniel Hedlund"]
  s.email       = ["daniel@digitree.org"]
  s.homepage    = "https://github.com/dhedlund/importu"
  s.summary     = "Because an import should be defined by a contract, not " +
                  "a sequence of commands"
  s.description = "Importu simplifies the process of defining and sharing " +
                  "contracts that structured data must conform to in order " +
                  "to be importable into your application."

  s.files            = `git ls-files`.split("\n")
  s.require_paths    = ["lib"]

  s.licenses = ["MIT"]

  s.metadata = {
    "homepage_uri"    => s.homepage,
    "source_code_uri" => s.homepage,
    "changelog_uri"   => "#{s.homepage}/blob/master/CHANGELOG.md",
    "bug_tracker_uri" => "#{s.homepage}/issues",
  }

  s.add_dependency "bigdecimal"
  s.add_dependency "csv"
  s.add_dependency "nokogiri", ">= 1.13"

  s.add_development_dependency "appraisal"
  s.add_development_dependency "bundler",      ">= 2.0"
  s.add_development_dependency "rspec",        "~> 3.13"
  s.add_development_dependency "simplecov",    "~> 0.22"

  # Code Quality
  s.add_development_dependency "rubocop", "~> 1.70"
  s.add_development_dependency "rubocop-performance", "~> 1.24"

  # YARD Documentation
  s.add_development_dependency "redcarpet" # For README.md
  s.add_development_dependency "yard"

end
