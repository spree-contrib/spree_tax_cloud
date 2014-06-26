Spree::Order.class_eval do

  def finalize!
    # lock all adjustments (coupon promotions, etc.)
    all_adjustments.each{|a| a.close}
    
    # tell TaxCloud to consider this order completed
    # TODO there is surely a cleaner way to set this hook
    transaction = Spree::TaxCloud.transaction_from_order(self)
    transaction.authorized_with_capture

    # update payment and shipment(s) states, and save
    updater.update_payment_state
    shipments.each do |shipment|
      shipment.update!(self)
      shipment.finalize!
    end

    updater.update_shipment_state
    save
    updater.run_hooks

    touch :completed_at

    deliver_order_confirmation_email unless confirmation_delivered?

    consider_risk
  end
  
end
