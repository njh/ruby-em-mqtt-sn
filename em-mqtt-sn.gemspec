#!/usr/bin/env ruby -rubygems
# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "em/mqtt-sn/version"

Gem::Specification.new do |gem|
  gem.name        = 'em-mqtt-sn'
  gem.version     = EventMachine::MQTTSN::VERSION
  gem.author      = 'Nicholas J Humfrey'
  gem.email       = 'njh@aelius.com'
  gem.homepage    = 'http://github.com/njh/ruby-em-mqtt-sn'
  gem.summary     = 'MQTT-SN for EventMachine'
  gem.description = 'This gem adds MQTT-SN protocol and gateway support to EventMachine.'
  gem.license     = 'Ruby' if gem.respond_to?(:license=)

  gem.files         = %w(README.md LICENSE.md NEWS.md) + Dir.glob('lib/**/*.rb')
  gem.test_files    = Dir.glob('spec/*_spec.rb')
  gem.executables   = %w(em-mqtt-sn-gateway)
  gem.require_paths = %w(lib)

  gem.add_runtime_dependency     'eventmachine'
  gem.add_runtime_dependency     'mqtt',        '>= 0.0.8'
  gem.add_runtime_dependency     'em-mqtt',     '>= 0.0.3'
  gem.add_development_dependency 'bundler',     '>= 1.0.14'
  gem.add_development_dependency 'yard',        '>= 0.7.2'
  gem.add_development_dependency 'rake',        '>= 0.8.7'
  gem.add_development_dependency 'rspec',       '>= 2.6.0'
end
