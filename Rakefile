ENV['BUNDLE_GEMFILE'] ||= File.expand_path('Gemfile', __dir__)
require 'bundler/setup' # Set up gems listed in the Gemfile.

# ------------------------------------------------------------
# Application code

File.expand_path('lib', __dir__).tap do |lib|
  $LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
end

# ------------------------------------------------------------
# CI

ENV['RAILS_ENV'] = 'test' if ENV['CI']

# ------------------------------------------------------------
# Custom tasks

desc 'Run tests, check test coverage, check code style, check for vulnerabilities, build gem'
task default: %i[coverage rubocop bundle:audit gem]
