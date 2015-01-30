# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vagrant-windows-domain/version'

Gem::Specification.new do |spec|
  spec.name          = "vagrant-windows-domain"
  spec.version       = Vagrant::WindowsDomain::VERSION
  spec.authors       = ["Matt Fellows"]
  spec.email         = ["matt.fellows@onegeek.com.au"]
  spec.summary       = "Windows Domain Provisioner for Vagrant"
  spec.description   = "Adds and Removes Windows Guests from a Windows Domain, as part of the standard machine lifecycle."
  spec.homepage      = "https://github.com/SEEK-Jobs/vagrant-windows-domain"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake", '~> 10.3', '>= 10.3.0'
  spec.add_development_dependency "bundler", "~> 1.6", '>= 1.6.0'
  spec.add_development_dependency "coveralls", "~> 0.7.1", '>= 0.7.1'
  spec.add_development_dependency "rspec-core", '~> 3.1', '>= 3.1.0'
  spec.add_development_dependency "rspec-expectations", '~> 3.1', '>= 3.1.0'
  spec.add_development_dependency "rspec-mocks", '~> 3.1', '>= 3.1.0'
  spec.add_development_dependency "rspec-its", "~> 1.0.1", '>= 1.0.0'
end
