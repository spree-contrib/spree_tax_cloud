Spree::Order.class_eval do
  self.state_machine.after_transition to: :complete, do: :capture_tax_cloud

  def capture_tax_cloud
    return unless is_taxed_using_tax_cloud?
    response = begin
      Spree::TaxCloud.transaction_from_order(self).authorized_with_capture
    rescue TaxCloud::Errors::ApiError => error
      error.as_json.except("__better_errors_bindings_stack")
    end
    log_tax_cloud response
  end

  # TaxRate.match is used here to check if the order is taxable by Tax Cloud.
  # It's not possible check against the order's tax adjustments because
  # an adjustment is not created for 0% rates. However, US orders must be
  # submitted to Tax Cloud even when the rate is 0%.
  def is_taxed_using_tax_cloud?
    Spree::TaxRate.match(self.tax_zone).any? do |rate|
      rate.calculator_type == "Spree::Calculator::TaxCloudCalculator"
    end
  end

  def log_tax_cloud(response)
    # Implement into your own application.
    # You could create your own Log::TaxCloud model then use either HStore or
    # JSONB to store the response.
    # The response argument carries the response from an order transaction.
  end
end
