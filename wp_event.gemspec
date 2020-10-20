# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'wp_event/version'

Gem::Specification.new do |spec|
  spec.name          = "wp_event"
  spec.version       = WPEvent::VERSION
  spec.authors       = ["Felix Wolfsteller"]
  spec.email         = ["felix.wolfsteller@gmail.com"]

  spec.summary       = %q{Populate a wordpress installation that has ev7l-events plugin installed with data}
  spec.description   = %q{Companion to add event, referee and event-categories data to a wordpress installation}
  spec.homepage      = "https://github.com/ecovillage/wp_event"
  spec.licenses      = ['GPL-3.0+']

  spec.required_ruby_version = '>= 2.3.0'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rubypress"
  spec.add_dependency "mime-types"
  spec.add_dependency "rest-client"
  spec.add_dependency "compostr", "~> 0.1.5"
  spec.add_dependency "iconv" #~> shadowed asciify dependency
  spec.add_dependency "asciify"

  spec.add_development_dependency "minitest"
  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
end
