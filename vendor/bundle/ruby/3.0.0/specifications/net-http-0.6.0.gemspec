# -*- encoding: utf-8 -*-
# stub: net-http 0.6.0 ruby lib

Gem::Specification.new do |s|
  s.name = "net-http".freeze
  s.version = "0.6.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "homepage_uri" => "https://github.com/ruby/net-http", "source_code_uri" => "https://github.com/ruby/net-http" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["NARUSE, Yui".freeze]
  s.bindir = "exe".freeze
  s.date = "2024-12-02"
  s.description = "HTTP client api for Ruby.".freeze
  s.email = ["naruse@airemix.jp".freeze]
  s.homepage = "https://github.com/ruby/net-http".freeze
  s.licenses = ["Ruby".freeze, "BSD-2-Clause".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.6.0".freeze)
  s.rubygems_version = "3.3.5".freeze
  s.summary = "HTTP client api for Ruby.".freeze

  s.installed_by_version = "3.3.5" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<uri>.freeze, [">= 0"])
  else
    s.add_dependency(%q<uri>.freeze, [">= 0"])
  end
end
