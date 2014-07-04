Spree::LineItem.class_eval do
  def tax_cloud_cache_key
    key = "Spree::LineItem "
    key << "#{self.id}: "
    key << "#{self.quantity}x"
    key << "<#{variant.cache_key}>"
    key << "@#{self.price}#{self.currency}"
  end  
end
