# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'seaboar/version'

Gem::Specification.new do |spec|
  spec.name          = "seaboar"
  spec.version       = Seaboar::VERSION
  spec.authors       = ["Ben Weintraub"]
  spec.email         = ["benweint@gmail.com"]
  spec.description   = %q{A pure Ruby gem for reading and writing CBOR (RFC 7049)}
  spec.summary       = %q{Read and write CBOR}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "guard"
end
