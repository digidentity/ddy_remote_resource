source 'https://rubygems.org'

# Specify your gem's dependencies in remote_resource.gemspec
gemspec

# CI runs the suite against each supported Rails line (see .github/workflows/ci.yml).
if (rails_version = ENV['RAILS_VERSION'])
  gem 'activesupport', "~> #{rails_version}"
  gem 'activemodel', "~> #{rails_version}"
end
