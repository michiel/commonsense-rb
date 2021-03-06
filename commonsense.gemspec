# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'commonsense/version'

Gem::Specification.new do |spec|
  spec.name          = "commonsense"
  spec.version       = Commonsense::VERSION
  spec.authors       = ["Michiel Kalkman"]
  spec.email         = ["michiel@michielkalkman.com"]
  spec.description   = %q{CommonSense API implementation}
  spec.summary       = %q{CommonSense API implementation}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "debugger"

  spec.add_dependency "faraday"
end
