ENV['RAILS_ENV'] ||= 'test'

require File.expand_path('../dummy/config/environment.rb',  __FILE__)

require 'rspec/rails'
require 'database_cleaner'
require 'factory_girl'
FactoryGirl.find_definitions
require 'ffaker'

Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].each { |f| require f }

require 'spree/testing_support/factories'
require 'spree/testing_support/capybara_ext'
require 'spree/testing_support/controller_requests'
require 'spree/testing_support/authorization_helpers'
require 'spree/testing_support/preferences'
require 'spree/testing_support/flash'
require 'spree/testing_support/url_helpers'

require 'capybara/poltergeist'
Capybara.javascript_driver = :poltergeist

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
  config.include Spree::TestingSupport::ControllerRequests
  config.include Spree::TestingSupport::Preferences
  config.include Spree::TestingSupport::Flash
  config.include Spree::TestingSupport::UrlHelpers

  # Official verification and test harness login credentials provided 7/8/14
  # by David Campbell of The Federal Tax Authority.
  # This account is configured to collect sales tax in the 24 SSUTA states:
  # AR, GA, IN, IA, KS, KY, MI, MN, NE, NV, NJ, NC, ND, OH, OK, RI, SD, TN, UT, VT, WA, WV, WI, and WY
  # The account does not collect sales tax in the remaining sales tax states:
  # AL, AK, AZ, CA, CO, CT, DC, FL, HI, ID, IL, LA, ME, MD, MA, MS, MO, NM, NY, PA, SC, TX, and VA
  config.before :suite do
    Spree::Config[:taxcloud_api_login_id] = '2D7D820'
    Spree::Config[:taxcloud_api_key]      = '0946110C-2AA9-4387-AD5C-4E1C551B8D0C'
    Spree::Config[:taxcloud_usps_user_id] = '000FEDTA0000'
    Spree::Config[:taxcloud_default_product_tic]  = '00000'
    Spree::Config[:taxcloud_shipping_tic]         = '11010'
  end

  config.before :each do
    DatabaseCleaner.strategy = RSpec.current_example.metadata[:js] ? :truncation : :transaction
    DatabaseCleaner.start
  end

  config.after :each do
    DatabaseCleaner.clean
  end

  config.color = true
  config.use_transactional_fixtures = false
  config.infer_base_class_for_anonymous_controllers = false
  config.infer_spec_type_from_file_location!
end
