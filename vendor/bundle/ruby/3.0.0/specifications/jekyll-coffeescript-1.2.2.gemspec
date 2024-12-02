# -*- encoding: utf-8 -*-
# stub: jekyll-coffeescript 1.2.2 ruby lib

Gem::Specification.new do |s|
  s.name = "jekyll-coffeescript".freeze
  s.version = "1.2.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Parker Moore".freeze]
  s.date = "2019-03-24"
  s.email = ["parkrmoore@gmail.com".freeze]
  s.homepage = "https://github.com/jekyll/jekyll-coffeescript".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3.0".freeze)
  s.rubygems_version = "3.3.5".freeze
  s.summary = "A CoffeeScript converter for Jekyll.".freeze

  s.installed_by_version = "3.3.5" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<coffee-script>.freeze, ["~> 2.2"])
    s.add_runtime_dependency(%q<coffee-script-source>.freeze, ["~> 1.12"])
    s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_development_dependency(%q<jekyll>.freeze, [">= 2.0"])
    s.add_development_dependency(%q<rake>.freeze, [">= 0"])
    s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
    s.add_development_dependency(%q<rubocop-jekyll>.freeze, ["~> 0.5"])
  else
    s.add_dependency(%q<coffee-script>.freeze, ["~> 2.2"])
    s.add_dependency(%q<coffee-script-source>.freeze, ["~> 1.12"])
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<jekyll>.freeze, [">= 2.0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<rspec>.freeze, [">= 0"])
    s.add_dependency(%q<rubocop-jekyll>.freeze, ["~> 0.5"])
  end
end
