File.expand_path('lib', __dir__).tap do |lib|
  $LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
end

ruby_version = '>= 2.7'

require 'berkeley_library/alma/module_info'

Gem::Specification.new do |spec|
  spec.name = BerkeleyLibrary::Alma::ModuleInfo::NAME
  spec.author = BerkeleyLibrary::Alma::ModuleInfo::AUTHOR
  spec.email = BerkeleyLibrary::Alma::ModuleInfo::AUTHOR_EMAIL
  spec.summary = BerkeleyLibrary::Alma::ModuleInfo::SUMMARY
  spec.description = BerkeleyLibrary::Alma::ModuleInfo::DESCRIPTION
  spec.license = BerkeleyLibrary::Alma::ModuleInfo::LICENSE
  spec.version = BerkeleyLibrary::Alma::ModuleInfo::VERSION
  spec.homepage = BerkeleyLibrary::Alma::ModuleInfo::HOMEPAGE

  spec.files = `git ls-files -z`.split("\x0")
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.required_ruby_version = ruby_version

  spec.add_dependency 'berkeley_library-logging', '~> 0.2'
  spec.add_dependency 'berkeley_library-marc', '~> 0.3.1'
  spec.add_dependency 'berkeley_library-util', '~> 0.1', '>= 0.1.2'
  spec.add_dependency 'nokogiri', '~> 1.12'

  spec.add_development_dependency 'bundle-audit', '~> 0.1'
  spec.add_development_dependency 'ci_reporter_rspec', '~> 1.0'
  spec.add_development_dependency 'colorize', '~> 0.8'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.10'
  spec.add_development_dependency 'rubocop', '= 1.11'
  spec.add_development_dependency 'rubocop-rake', '= 0.6.0'
  spec.add_development_dependency 'rubocop-rspec', '= 2.4.0'
  spec.add_development_dependency 'simplecov', '~> 0.21'
  spec.add_development_dependency 'simplecov-rcov', '~> 0.2'
  spec.add_development_dependency 'webmock', '~> 3.12'
  spec.add_development_dependency 'yard', '~> 0.9.27'
end
