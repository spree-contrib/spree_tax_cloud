module SpreeTaxCloud
  class Engine < Rails::Engine
    require 'spree/core'
    isolate_namespace Spree
    engine_name 'spree_tax_cloud'

    config.autoload_paths += %W(#{config.root}/lib)

    # use rspec for tests
    config.generators do |generator|
      generator.test_framework :rspec
    end

    initializer "spree_tax_cloud.permitted_attributes" do |_app|
      Spree::PermittedAttributes.product_attributes << :tax_cloud_tic
    end

    def self.activate
      if SpreeTaxCloud::Engine.frontend_available?
        Rails.application.config.assets.precompile += [
          'lib/assets/javascripts/spree/frontend/spree_tax_cloud.js',
          'lib/assets/stylesheets/spree/frontend/spree_tax_cloud.css'
        ]
        Dir.glob(File.join(File.dirname(__FILE__), "../../app/**/frontend/*_decorator*.rb")) do |c|
          Rails.configuration.cache_classes ? require(c) : load(c)
        end
      end
    end

    def self.frontend_available?
      @@frontend_available ||= ::Rails::Engine.subclasses.map(&:instance).map { |e| e.class.to_s }.include?('Spree::Frontend::Engine')
    end

    if self.frontend_available?
      paths["app/controllers"] << "lib/controllers/frontend"
    end

    config.to_prepare &method(:activate).to_proc
    config.after_initialize do
      Dir.glob(File.join(File.dirname(__FILE__), '../../app/*/spree/**/*_decorator*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end
  end
end
