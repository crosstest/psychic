# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'psychic/runner/version'

Gem::Specification.new do |spec|
  spec.name          = 'psychic-runner'
  spec.version       = Psychic::Runner::VERSION
  spec.authors       = ['Max Lincoln']
  spec.email         = ['max@devopsy.com']
  spec.summary       = 'Psychic runs anything.'
  spec.description   = 'Provides cross-project aliases for running tasks or similar code samples.'
  # spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'thor', '~> 0.19'
  spec.add_dependency 'mixlib-shellout', '~> 1.3' # Used for MRI
  # spec.add_dependency "buff-shell_out", "~> 0.1"  # Used for JRuby
  spec.add_dependency 'mustache', '~> 0.99'
  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rake-notes'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.18', '<= 0.27'
  spec.add_development_dependency 'rubocop-rspec', '~> 1.2'
  spec.add_development_dependency 'aruba'
end
