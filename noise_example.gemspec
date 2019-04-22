# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'noise/example/version'

Gem::Specification.new do |spec|
  spec.name          = 'noise_example'
  spec.version       = Noise::Example::VERSION
  spec.authors       = ['Hajime Yamaguchi']
  spec.email         = ['gen.yamaguchi0@gmail.com']

  spec.summary       = 'Example of Noise Protocol Framework using noise-ruby'
  spec.description   = 'Example of Noise Protocol Framework using noise-ruby'
  spec.homepage      = 'https://github.com/Yamaguchi/noise_example'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.12'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'

  spec.add_runtime_dependency 'algebrick'
  spec.add_runtime_dependency 'concurrent-ruby'
  spec.add_runtime_dependency 'concurrent-ruby-edge'
  spec.add_runtime_dependency 'eventmachine'
  spec.add_runtime_dependency 'noise-ruby'
  spec.add_runtime_dependency 'secp256k1-ruby'
end
