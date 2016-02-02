require 'simplecov'
require 'coveralls'

require 'vagrant-windows-domain/version'
require 'vagrant-windows-domain/plugin'
require 'rspec/its'
require 'base'

SimpleCov.formatters = [
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
]

SimpleCov.start do
  coverage_dir('tmp/coverage')
  add_filter '/spec/'
end

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end
  config.color = true
  config.tty = true
end