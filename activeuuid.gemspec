# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "activeuuid/version"

Gem::Specification.new do |s|
  s.name        = "activeuuid"
  s.version     = Activeuuid::VERSION
  s.authors     = ["Nate Murray"]
  s.email       = ["nate@natemurray.com"]
  s.homepage    = "http://www.eigenjoy.com"
  s.summary     = %q{Add binary UUIDs to ActiveRecord in MySQL}
  s.description = %q{Add binary (not string) UUIDs to ActiveRecord in MySQL}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # s.add_development_dependency "rspec"
  s.add_runtime_dependency "uuidtools"
end
