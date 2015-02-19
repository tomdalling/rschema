lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
require 'rschema/version'

Gem::Specification.new do |s|
  s.name        = 'rschema'
  s.summary     = 'Schema-based validation and coercion for Ruby data structures'
  s.homepage    = 'http://www.tomdalling.com/rschema'
  s.licenses    = ['MIT']
  s.description = <<-GEM_DESC
    Schema-based validation and coercion for Ruby data structures. Heavily inspired
    by (read: stolen from) Prismatic/schema for Clojure.
  GEM_DESC

  s.version = RSchema::VERSION
  s.authors = ['Tom Dalling']
  s.email = ['tom' + '@' + 'tomdalling.com']

  s.files = Dir['lib/**/*'] + %w{LICENSE.txt README.md}
  s.add_development_dependency 'rspec', '~> 3.0'
  s.add_development_dependency 'rake', '~> 10.0'
  s.add_development_dependency 'gem-release', '~> 0.7'
  s.add_development_dependency 'pry', '~> 0'
  s.require_paths = ['lib']
end
