
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "active_support/cache/dalli_store_with_cas"

Gem::Specification.new do |spec|
  spec.name          = "dalli-store-with-cas"
  spec.version       = ActiveSupport::Cache::DalliStoreWithCas::DALLI_STORE_WITH_CAS_VERSION
  spec.authors       = ["Misha Conway"]
  spec.email         = ["mishaAconway@gmail.com"]

  spec.summary       = %q{A version of ActiveSupport::Cache::DalliStore with CAS support compatible with IdentityCache}
  spec.homepage      = "https://github.com/MishaConway/dalli-store-with-cas"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
	spec.add_development_dependency 'dalli'
end
