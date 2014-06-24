# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'remote_resource/version'

Gem::Specification.new do |spec|
  spec.name          = "remote_resource"
  spec.version       = RemoteResource::VERSION
  spec.authors       = ["Jan van der Pas"]
  spec.email         = ["jvanderpas@digidentity.eu"]
  spec.summary       = %q{RemoteResource, a gem to use resources with REST services.}
  spec.description   = %q{RemoteResource, a gem to use resources with REST services. A replacement for ActiveResource gem.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"

  spec.add_runtime_dependency 'activesupport'
  spec.add_runtime_dependency 'activemodel'
  spec.add_runtime_dependency 'virtus'
  spec.add_runtime_dependency 'typhoeus'
end
