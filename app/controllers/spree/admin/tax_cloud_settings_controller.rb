module Spree
  class Admin::TaxCloudSettingsController < Admin::BaseController

    respond_to  :html

    def show
    end

    def update
      taxpref = params[:settings]
      Spree::Config.taxcloud_api_login_id = taxpref[:taxcloud_api_login_id]
      Spree::Config.taxcloud_api_key = taxpref[:taxcloud_api_key]
      Spree::Config.taxcloud_default_product_tic = taxpref[:taxcloud_default_product_tic]
      Spree::Config.taxcloud_shipping_tic = taxpref[:taxcloud_shipping_tic]
      Spree::Config.taxcloud_usps_user_id = taxpref[:taxcloud_usps_user_id]

      respond_to do |format|
        format.html {
          redirect_to admin_tax_cloud_settings_path
        }
      end
    end
  end
end
