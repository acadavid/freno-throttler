# -- encoding: utf-8 --
$:.unshift File.expand_path("../lib", __FILE__)
require_relative "lib/freno/throttler/version"

Gem::Specification.new do |spec|
  spec.name                  = "freno-throttler"
  spec.version               = Freno::Throttler::VERSION
  spec.authors               = ["Miguel Fernández"]
  spec.email                 = ["opensource+freno-throttler@github.com"]

  spec.summary               = %q{A library to throttle access to databases that talks to Freno}
  spec.description           = %q{freno-thottler is a ruby library that interacts with
                                  Freno using HTTP to throttle access to databases. Freno
                                  is a throttling service and its source code is available
                                  at https://github.com/github/freno}
  spec.homepage              = "https://github.com/github/freno-throttler"
  spec.license               = "MIT"
  spec.required_ruby_version = ">= 2.0.0"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.executables   = []
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "freno-client", "~> 0"
end
