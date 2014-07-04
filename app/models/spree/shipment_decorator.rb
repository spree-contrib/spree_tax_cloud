Spree::Shipment.class_eval do
  def tax_cloud_cache_key
    binding.pry
    "#{self.cache_key}--order: #{self.order.cache_key}"
  end  
end
