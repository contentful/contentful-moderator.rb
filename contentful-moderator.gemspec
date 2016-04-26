# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'contentful/moderator/version'

Gem::Specification.new do |spec|
  spec.name          = "contentful-moderator"
  spec.version       = Contentful::Moderator::VERSION
  spec.authors       = ["Contentful GmbH (David Litvak Bruno)"]
  spec.email         = ["david.litvak@contentful.com"]

  spec.summary       = %q{Contentful Moderation Workflow Gem}
  spec.description   = %q{Contentful Moderation Workflow Gem}
  spec.homepage      = "https://www.contentful.com"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'contentful-webhook-listener', '~> 0.2'
  spec.add_runtime_dependency 'mail', '~> 2.6'
  spec.add_runtime_dependency 'hashie', '~> 3.4'

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "guard"
  spec.add_development_dependency "guard-rspec"
  spec.add_development_dependency "pry"
end
