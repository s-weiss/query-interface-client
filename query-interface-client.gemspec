# -*- encoding: utf-8 -*-

require File.join(File.dirname(__FILE__), 'lib', 'query-interface-client', 'version')

require 'date'

Gem::Specification.new do |s|
  s.name = "query-interface-client"
  s.version = QueryInterface::Client::VERSION

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Andreas Kopecky <andreas.kopecky@radarservices.com>", "Anton Bangratz <anton.bangratz@radarservices.com>", "Martin Natano <martin.natano@radarservices.com"]
  s.date = Date.today.strftime
  s.description = "Client for the radar query interface"
  s.email = "gems [a] radarservices [d] com"
  s.files            = `git ls-files`.split("\n").reject { |file| file == '.gitignore' }
  s.test_files       = `git ls-files -- {spec}/*`.split("\n")
  s.extra_rdoc_files = %w[LICENSE README.md]

  s.homepage = "http://github.com/rs-dev/query-interface-client"
  s.require_paths = ["lib"]
  # s.rubygems_version = "1.8.24"
  s.summary = "Client for the radar query interface"
  s.license = "ISC"

  s.add_runtime_dependency(%q<her>)
  s.add_runtime_dependency(%q<will_paginate>)
  s.add_development_dependency(%q<rake>)
  s.add_development_dependency(%q<rspec>)
end
