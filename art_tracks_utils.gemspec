# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'art_tracks_utils/version'

Gem::Specification.new do |spec|
  spec.name          = "art_tracks_utils"
  spec.version       = ArtTracksUtils::VERSION
  spec.authors       = ["David Newbury"]
  spec.email         = ["newburyd@cmoa.org"]
  spec.summary       = "A collection of command line utilities for Art Tracks"
  spec.description   = ""
  spec.homepage      = "http://www.museumprovenance.com"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]


  spec.add_runtime_dependency "museum_provenance"  
  spec.add_runtime_dependency "art_tracks"  

  spec.add_runtime_dependency "commander"  
  spec.add_runtime_dependency 'damerau-levenshtein'
  spec.add_runtime_dependency 'ruby-progressbar'
  spec.add_runtime_dependency "elasticsearch"  
  spec.add_runtime_dependency "net-sftp"
  spec.add_runtime_dependency 'hashie'

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
end
