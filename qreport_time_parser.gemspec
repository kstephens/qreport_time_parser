# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'qreport_time_parser/version'

Gem::Specification.new do |spec|
  spec.name          = "qreport_time_parser"
  spec.version       = QreportTimeParser::VERSION
  spec.authors       = ["Kurt Stephens"]
  spec.email         = ["ks.github@kurtstephens.com"]
  spec.description   = %q{Parse time expressions with accuracy ranges.}
  spec.summary       = %q{Parse time expressions with accuracy ranges.}
  spec.homepage      = "http://github.com/kstephens/qreport_time_parser"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency 'rake', '>= 0.9.0'
  spec.add_development_dependency 'rspec', '~> 2.12'
  spec.add_development_dependency 'simplecov', '~> 0.7.1'
  spec.add_development_dependency "guard", "~> 1.8.0"
  spec.add_development_dependency "guard-rspec", "~> 3.0.2"
  spec.add_development_dependency "cassava", "~> 0.0.1"
end
