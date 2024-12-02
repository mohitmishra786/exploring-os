# -*- encoding: utf-8 -*-
# stub: ffi 1.17.0 ruby lib
# stub: ext/ffi_c/extconf.rb

Gem::Specification.new do |s|
  s.name = "ffi".freeze
  s.version = "1.17.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/ffi/ffi/issues", "changelog_uri" => "https://github.com/ffi/ffi/blob/master/CHANGELOG.md", "documentation_uri" => "https://github.com/ffi/ffi/wiki", "mailing_list_uri" => "http://groups.google.com/group/ruby-ffi", "source_code_uri" => "https://github.com/ffi/ffi/", "wiki_uri" => "https://github.com/ffi/ffi/wiki" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Wayne Meissner".freeze]
  s.cert_chain = ["-----BEGIN CERTIFICATE-----\nMIIEBDCCAmygAwIBAgIBAzANBgkqhkiG9w0BAQsFADAoMSYwJAYDVQQDDB1sYXJz\nL0RDPWdyZWl6LXJlaW5zZG9yZi9EQz1kZTAeFw0yNDAyMjgxOTMxNDdaFw0yNTAy\nMjcxOTMxNDdaMCgxJjAkBgNVBAMMHWxhcnMvREM9Z3JlaXotcmVpbnNkb3JmL0RD\nPWRlMIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEAwum6Y1KznfpzXOT/\nmZgJTBbxZuuZF49Fq3K0WA67YBzNlDv95qzSp7V/7Ek3NCcnT7G+2kSuhNo1FhdN\neSDO/moYebZNAcu3iqLsuzuULXPLuoU0GsMnVMqV9DZPh7cQHE5EBZ7hlzDBK7k/\n8nBMvR0mHo77kIkapHc26UzVq/G0nKLfDsIHXVylto3PjzOumjG6GhmFN4r3cP6e\nSDfl1FSeRYVpt4kmQULz/zdSaOH3AjAq7PM2Z91iGwQvoUXMANH2v89OWjQO/NHe\nJMNDFsmHK/6Ji4Kk48Z3TyscHQnipAID5GhS1oD21/WePdj7GhmbF5gBzkV5uepd\neJQPgWGwrQW/Z2oPjRuJrRofzWfrMWqbOahj9uth6WSxhNexUtbjk6P8emmXOJi5\nchQPnWX+N3Gj+jjYxqTFdwT7Mj3pv1VHa+aNUbqSPpvJeDyxRIuo9hvzDaBHb/Cg\n9qRVcm8a96n4t7y2lrX1oookY6bkBaxWOMtWlqIprq8JZXM9AgMBAAGjOTA3MAkG\nA1UdEwQCMAAwCwYDVR0PBAQDAgSwMB0GA1UdDgQWBBQ4h1tIyvdUWtMI739xMzTR\n7EfMFzANBgkqhkiG9w0BAQsFAAOCAYEArBmHSfnUyNWf3R1Fx0mMHloWGdcKn2D2\nBsqTApXU2nADiyppIqRq4b9e7hw342uzadSLkoQcEFOxThLRhAcijoWfQVBcsbV/\nZsCY1qlUTIJuSWxaSyS4efUX+N4eMNyPM9oW/sphlWFo0DgI34Y9WB6HDzH+O71y\nR7PARke3f4kYnRJf5yRQLPDrH9UYt9KlBQm6l7XMtr5EMnQt0EfcmZEi9H4t/vS2\nhaxvpFMdAKo4H46GBYNO96r6b74t++vgQSBTg/AFVwvRZwNSrPPcBfb4xxeEAhRR\nx+LU7feIH7lZ//3buiyD03gLAEtHXai0Y+/VfuWIpwYJAl2BO/tU7FS/dtbJq9oc\ndI36Yyzy+BrCM0WT4oCsagePNb97FaNhl4F6sM5JEPT0ZPxRx0i3G4TNNIYziVos\n5wFER6XhvvLDFAMh/jMg+s7Wd5SbSHgHNSUaUGVtdWkVPOer6oF0aLdZUR3CETkn\n5nWXZma/BUd3YgYA/Xumc6QQqIS4p7mr\n-----END CERTIFICATE-----\n".freeze]
  s.date = "2024-06-02"
  s.description = "Ruby FFI library".freeze
  s.email = "wmeissner@gmail.com".freeze
  s.extensions = ["ext/ffi_c/extconf.rb".freeze]
  s.files = ["ext/ffi_c/extconf.rb".freeze]
  s.homepage = "https://github.com/ffi/ffi/wiki".freeze
  s.licenses = ["BSD-3-Clause".freeze]
  s.rdoc_options = ["--exclude=ext/ffi_c/.*\\.o$".freeze, "--exclude=ffi_c\\.(bundle|so)$".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5".freeze)
  s.rubygems_version = "3.3.5".freeze
  s.summary = "Ruby FFI".freeze

  s.installed_by_version = "3.3.5" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<rake>.freeze, ["~> 13.0"])
    s.add_development_dependency(%q<rake-compiler>.freeze, ["~> 1.1"])
    s.add_development_dependency(%q<rake-compiler-dock>.freeze, ["~> 1.0"])
    s.add_development_dependency(%q<rspec>.freeze, ["~> 2.14.1"])
  else
    s.add_dependency(%q<rake>.freeze, ["~> 13.0"])
    s.add_dependency(%q<rake-compiler>.freeze, ["~> 1.1"])
    s.add_dependency(%q<rake-compiler-dock>.freeze, ["~> 1.0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 2.14.1"])
  end
end
