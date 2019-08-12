source "https://rubygems.org"
gemspec

version = ENV["AS_VERSION"] || "5.2.0.rc1"
as_version = case version
             when "master"
	             { github: "rails/rails" }
             else
	             "~> #{version}"
             end

gem "activesupport", as_version

