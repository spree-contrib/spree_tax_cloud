# -*- encoding: utf-8 -*-
version = File.read(File.expand_path("../SPREE_TAXCLOUD_VERSION",__FILE__)).strip

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY

  s.name        = 'spree_tax_cloud'
  s.version     =  version
  s.authors     = ["Jerrold Thompson"]
  s.email       = 'jet@whidbey.com'
  s.homepage    = 'https://github.com/spree-contrib/spree_tax_cloud.git'
  s.summary     = 'Spree extension providing Tax Cloud services'
  s.description = 'Spree extension for providing Tax Cloud services in USA.'

  s.required_ruby_version = '>= 2.2.7'

  spree_version = '>= 3.1.0', '< 4.0'
  s.add_dependency 'spree_backend', spree_version
  s.add_dependency 'spree_core', spree_version
  s.add_dependency 'spree_extension'

  s.add_runtime_dependency 'savon', '~> 2.5.1'
  s.add_runtime_dependency 'tax_cloud', '~> 0.3.0'

  s.add_development_dependency 'spree_frontend', spree_version
  s.add_development_dependency 'capybara'
  s.add_development_dependency 'poltergeist'
  s.add_development_dependency 'coffee-rails'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'factory_girl_rails'
  s.add_development_dependency 'ffaker'
  s.add_development_dependency 'generator_spec'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'sass-rails'
  s.add_development_dependency 'selenium-webdriver'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'appraisal'
  s.add_development_dependency 'pg'
  s.add_development_dependency 'mysql2'
end
