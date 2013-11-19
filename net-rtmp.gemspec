# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'net/rtmp/version'

Gem::Specification.new do |spec|
  spec.name          = 'net-rtmp'
  spec.version       = Net::RTMP::VERSION
  spec.authors       = ['Matt Huggins']
  spec.email         = ['matt.huggins@gmail.com']
  spec.description   = %q{RTMP client library}
  spec.summary       = %q{Net/RTMP is a simple client library for the RTMP protocol.}
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'RocketAMF'
  #spec.add_dependency 'em-rtmp'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
end
