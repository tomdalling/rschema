lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'rschema/version'

Gem::Specification.new do |s|
  s.name        = 'rschema'
  s.summary     = 'Schema-based validation and coercion for Ruby data structures'
  s.homepage    = 'https://github.com/tomdalling/rschema'
  s.license     = 'Apache-2.0'
  s.description = <<-GEM_DESC
    Schema-based validation and coercion for Ruby data structures, inspired
    by Prismatic/schema for Clojure.
  GEM_DESC

  s.version = RSchema::VERSION
  s.required_ruby_version = '>= 2.2.7'
  s.authors = ['Tom Dalling']
  s.email = ['tom' + '@' + 'tomdalling.com']
  s.require_paths = ['lib']
  s.files = Dir['lib/**/*'] + %w{LICENSE.txt README.md}

  s.add_runtime_dependency 'docile', '~> 1.2'

  s.add_development_dependency 'gem-release'
  s.add_development_dependency 'yard'
  s.add_development_dependency 'rubocop', '~> 0.88'

  # for testing
  s.add_development_dependency 'rspec', '~> 3.5'
  s.add_development_dependency 'rails', '~> 5.1'
  s.add_development_dependency 'rack-test', '~> 0.6.3'
  s.add_development_dependency 'byebug'
  s.add_development_dependency 'pry'
  # code climate doesn't support v0.18+
  # see: https://github.com/codeclimate/test-reporter/issues/413
  s.add_development_dependency 'simplecov', '< 0.18'

  # for benchmarking
  s.add_development_dependency 'benchmark-ips'
  s.add_development_dependency 'dry-schema'
end
