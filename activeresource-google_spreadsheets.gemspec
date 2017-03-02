# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'google_spreadsheets/version'

Gem::Specification.new do |spec|
  spec.name          = "activeresource-google_spreadsheets"
  spec.version       = GoogleSpreadsheets::VERSION
  spec.authors       = ["Chihiro Ito", "Toru KAWAMURA"]
  spec.email         = ["tkawa@4bit.net"]
  spec.description   = %q{Google Spreadsheets accessor with ActiveResource}
  spec.summary       = %q{Google Spreadsheets accessor with ActiveResource}
  spec.homepage      = "https://github.com/tkawa/activeresource-google_spreadsheets"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'activeresource', '~> 4.0.0'
  spec.add_dependency 'activesupport'
  spec.add_dependency 'google-api-client', '~> 0.8.6'

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
