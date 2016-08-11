# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'secure_data_bag/version'

Gem::Specification.new do |spec|
  spec.name          = 'secure_data_bag'
  spec.version       = SecureDataBag::VERSION
  spec.authors       = ['Jonathan Serafini']
  spec.email         = ['jonathan@lightspeedretail.com']
  spec.summary       = 'Mechanism to partially encryot data bag items'
  spec.description   = IO.read(File.join(File.dirname(__FILE__), 'README.md'))
  spec.license       = 'MIT'
  spec.homepage      =
    'https://github.com/JonathanSerafini/chef-secure_data_bag'
  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency  'chef'

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'cookstyle'
end
