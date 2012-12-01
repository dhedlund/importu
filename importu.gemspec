$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'importu/version'

Gem::Specification.new do |s|
  s.name        = 'importu'
  s.version     = Importu::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Daniel Hedlund']
  s.email       = ['daniel@lincracy.com']
  s.homepage    = 'https://github.com/lincracy/importu'
  s.summary     = 'A framework for importing data'
  s.description = 'Importu is a framework for importing data'

  s.files            = `git ls-files`.split("\n")
  s.test_files       = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths    = ['lib']

  s.licenses = ['MIT']
  
  s.add_dependency 'activesupport', ['>= 3.0.0']
  s.add_dependency 'activerecord',  ['>= 3.0.0']
  s.add_dependency 'nokogiri'

  s.add_development_dependency 'bundler',      ['>= 1.0.0']
  s.add_development_dependency 'rspec',        ['>= 0']
  s.add_development_dependency 'rdoc',         ['>= 0']
  s.add_development_dependency 'factory_girl', ['>= 3.5.0']
end
