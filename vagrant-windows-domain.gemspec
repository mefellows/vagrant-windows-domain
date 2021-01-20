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
  spec.homepage      = "https://github.com/mefellows/vagrant-windows-domain"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake"
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "coveralls"
  spec.add_development_dependency "rspec-core"
  spec.add_development_dependency "rspec-expectations"
  spec.add_development_dependency "rspec-mocks"
  spec.add_development_dependency "rspec-its"
end
