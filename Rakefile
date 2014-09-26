$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'bundler/version'
 
task :build do
  system 'gem build rschema.gemspec'
end
 
task :release => :build do
  system "gem push bundler-#{RSchema::VERSION}"
end
