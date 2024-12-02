# -*- encoding: utf-8 -*-
# stub: faraday-net_http 3.4.0 ruby lib

Gem::Specification.new do |s|
  s.name = "faraday-net_http".freeze
  s.version = "3.4.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/lostisland/faraday-net_http/releases/tag/v3.4.0", "homepage_uri" => "https://github.com/lostisland/faraday-net_http", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/lostisland/faraday-net_http" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jan van der Pas".freeze]
  s.date = "2024-11-13"
  s.description = "Faraday adapter for Net::HTTP".freeze
  s.email = ["janvanderpas@gmail.com".freeze]
  s.homepage = "https://github.com/lostisland/faraday-net_http".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.0.0".freeze)
  s.rubygems_version = "3.3.5".freeze
  s.summary = "Faraday adapter for Net::HTTP".freeze

  s.installed_by_version = "3.3.5" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<net-http>.freeze, [">= 0.5.0"])
  else
    s.add_dependency(%q<net-http>.freeze, [">= 0.5.0"])
  end
end
