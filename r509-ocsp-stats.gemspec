$:.push File.expand_path("../lib", __FILE__)
require "r509/ocsp/stats/version"

spec = Gem::Specification.new do |s|
  s.name = 'r509-ocsp-stats'
  s.version = R509::Ocsp::Stats::VERSION
  s.platform = Gem::Platform::RUBY
  s.summary = "A (relatively) simple stats system written to work with r509-ocsp-responder"
  s.description = 'Taking about stats here. What, you want more info?'
  s.add_dependency 'r509', '~>0.7'
  s.add_dependency 'redis'
  s.add_dependency 'dependo'
  s.add_development_dependency 'rspec', '>=2.11'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'syntax'
  s.add_development_dependency 'rack-test'
  s.add_development_dependency 'rcov' if RUBY_VERSION.split('.')[1].to_i == 8
  s.add_development_dependency 'simplecov' if RUBY_VERSION.split('.')[1].to_i == 9
  s.author = "Sean Schulte"
  s.email = "sirsean@gmail.com"
  s.homepage = "http://vikinghammer.com"
  s.required_ruby_version = ">= 1.9.3"
  s.files = %w(README.md Rakefile) + Dir["{lib,script,spec,doc,cert_data}/**/*"]
  s.test_files= Dir.glob('test/*_spec.rb')
  s.require_path = "lib"
end

