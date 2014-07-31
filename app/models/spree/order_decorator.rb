Spree::Order.class_eval do

  self.state_machine.after_transition to: :complete, do: :capture_tax_cloud

  self.state_machine.before_transition to: :delivery, do: :tax_cloud_verify_address

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
    is_tax_cloud = Spree::TaxRate.match(self).any? { |rate| rate.calculator_type == "Spree::Calculator::TaxCloudCalculator" }
    return is_tax_cloud
  end
  
  def tax_cloud_verify_address
    tax_cloud_address = Spree::TaxCloud.address_from_spree_address(self.ship_address)
    address_response = tax_cloud_address.verify_address
    spree_response_address = Spree::TaxCloud.spree_address_from_address(address_response)
    
  end
  
end
