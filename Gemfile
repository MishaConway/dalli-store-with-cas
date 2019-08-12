source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in dalli-store-with-with-cas.gemspec
gemspec

version = ENV["AS_VERSION"] || "5.2.0.rc1"
as_version = case version
             when "master"
	             { github: "rails/rails" }
             else
	             "~> #{version}"
             end

gem "activesupport", as_version

group :test do
	gem "mocha"
end
