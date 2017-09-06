$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "importu/version"

Gem::Specification.new do |s|
  s.name        = "importu"
  s.version     = Importu::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Daniel Hedlund"]
  s.email       = ["daniel@digitree.org"]
  s.homepage    = "https://github.com/dhedlund/importu"
  s.summary     = "A framework for importing data"
  s.description = "Importu is a framework for importing data"

  s.files            = `git ls-files`.split("\n")
  s.test_files       = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths    = ["lib"]

  s.licenses = ["MIT"]
  
  s.add_dependency "multi_json",    ["~> 1.0"]
  s.add_dependency "nokogiri"

  s.add_development_dependency "bundler",      [">= 1.0.0"]
  s.add_development_dependency "rspec",        ["~> 3.6"]
  s.add_development_dependency "rdoc",         [">= 0"]
  s.add_development_dependency "simplecov",    ["~> 0.14"]
  s.add_development_dependency "appraisal"

end
