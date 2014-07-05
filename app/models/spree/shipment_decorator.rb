Spree::Shipment.class_eval do
  def tax_cloud_cache_key
    "#{self.cache_key}--order:#{self.order.cache_key}--from:#{self.stock_location.cache_key}--to:#{self.order.shipping_address.cache_key}"
  end  
end
