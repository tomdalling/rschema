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
  s.required_ruby_version = '>= 2.0.0'
  s.authors = ['Tom Dalling']
  s.email = ['tom' + '@' + 'tomdalling.com']
  s.require_paths = ['lib']
  s.files = Dir['lib/**/*'] + %w{LICENSE.txt README.md}

  s.add_runtime_dependency 'docile', '~> 1.1'

  s.add_development_dependency 'rspec', '~> 3.0'
  s.add_development_dependency 'rake', '~> 10.0'
  s.add_development_dependency 'gem-release', '~> 0.7'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'byebug'
  s.add_development_dependency 'yard'

  # for benchmarking
  s.add_development_dependency 'benchmark-ips'
  s.add_development_dependency 'activemodel'
  s.add_development_dependency 'actionpack'
  s.add_development_dependency 'dry-validation'
end
