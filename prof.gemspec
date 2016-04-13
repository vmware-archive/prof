# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'prof/version'

Gem::Specification.new do |spec|
  spec.name        = 'prof'
  spec.version     = Prof::VERSION
  spec.authors     = ['CF London']
  spec.email       = ['cf-london@pivotallabs.com']
  spec.licenses    = ['Copyright (c) Pivotal Software, Inc.']
  spec.summary     = 'A gem to test CF service brokers'
  spec.description = 'A gem to test Cloud Foundry service brokers'
  spec.homepage    = 'http://github.com/pivotal-cf-experimental/prof'

  spec.post_install_message = "Prof now requires qt5-qmake qt5-default libqt5webkit5-dev to be available. Any Dock It invocations should not use `bundle exec`, and instead install and invoke the dock_it gem directly"

  spec.files         = Dir.glob('lib/**/*') + ['LEGAL']
  spec.executables   = spec.files.grep(/^bin\//) { |f| File.basename(f) }
  spec.require_paths = %w(lib)

  spec.add_development_dependency 'gem-release'
  spec.add_development_dependency 'gemfury', '>= 0.4.25'
  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'terminal-notifier-guard'
  spec.add_development_dependency 'webmock'

  spec.add_dependency 'bosh_cli'
  spec.add_dependency 'capybara'
  spec.add_dependency 'capybara-webkit'
  spec.add_dependency 'cf-uaa-lib', '~> 3.2.0'
  spec.add_dependency 'ci_reporter'
  spec.add_dependency 'faraday'
  spec.add_dependency 'faraday_middleware'
  spec.add_dependency 'httmultiparty'
  spec.add_dependency 'hula', '~> 0.8.3'
  spec.add_dependency 'net-ssh-gateway'
  spec.add_dependency 'nokogiri'
  spec.add_dependency 'poltergeist'
  spec.add_dependency 'rspec', '~> 3.3'
  spec.add_dependency 'rspec_junit_formatter'
  spec.add_dependency 'rubyzip', '~> 1.1'
  spec.add_dependency 'opsmgr', '~> 0.34.17'
end
