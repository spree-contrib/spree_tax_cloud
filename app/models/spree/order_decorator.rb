Spree::Order.class_eval do

  self.state_machine.after_transition to: :complete, do: :capture_tax_cloud

  def capture_tax_cloud
    if is_taxed_using_tax_cloud? == false
      return
    end

    transaction = Spree::TaxCloud.transaction_from_order(self)
    response =  transaction.authorized_with_capture
    if response != "OK"
      Rails.logger.error "ERROR: TaxCloud returned an order capture response of #{response}."
    end
  end

  def is_taxed_using_tax_cloud?
    # TaxRate.match is used here to check if the order is taxable by Tax Cloud.
    # It's not possible check against the order's tax adjustments because
    # an adjustment is not created for 0% rates. However, US orders must be
    # submitted to Tax Cloud even when the rate is 0%.
    is_tax_cloud = Spree::TaxRate.match(self.tax_zone).any? do |rate|
      rate.calculator_type == "Spree::Calculator::TaxCloudCalculator"
    end
    return is_tax_cloud
  end
end
