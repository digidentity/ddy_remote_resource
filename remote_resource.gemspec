# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'remote_resource/version'

Gem::Specification.new do |spec|
  spec.name          = 'ddy_remote_resource'
  spec.version       = RemoteResource::VERSION
  spec.authors       = ['Digidentity', 'Johnny Dongelmans', 'Jan van der Pas']
  spec.email         = ['development@digidentity.com']
  spec.summary       = %q{RemoteResource, a gem to use resources with REST services.}
  spec.description   = %q{RemoteResource, a gem to use resources with REST services. A replacement for ActiveResource gem.}
  spec.homepage      = 'https://github.com/digidentity/ddy_remote_resource'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake', '~> 12.3'
  spec.add_development_dependency 'rspec', '~> 3.1'
  spec.add_development_dependency 'pry', '~> 0.10'
  spec.add_development_dependency 'webmock', '~> 3'
  spec.add_development_dependency 'guard', '~> 2.14'
  spec.add_development_dependency 'guard-rspec', '~> 4.7'
  spec.add_development_dependency 'terminal-notifier-guard', '~> 1.6'

  spec.add_runtime_dependency 'activesupport', '>= 4.1', '< 8'
  spec.add_runtime_dependency 'activemodel', '>= 4.1', '< 8'
  spec.add_runtime_dependency 'virtus', '~> 1.0', '>= 1.0.4'
  spec.add_runtime_dependency 'mime-types', '~> 3.0'
  spec.add_runtime_dependency 'ethon'
  spec.add_runtime_dependency 'typhoeus', '>= 0.7'
  spec.add_runtime_dependency 'request_store', '~> 1.6'
end
