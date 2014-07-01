Spree::Order.class_eval do

  self.state_machine.after_transition to: :complete, do: :capture_tax_cloud  

  def capture_tax_cloud
    transaction = Spree::TaxCloud.transaction_from_order(self)
    response =  transaction.authorized_with_capture 
    if response != "OK"
      Rails.logger.error "ERROR: TaxCloud returned an order capture response of #{response}."
    end
  end
  
end
