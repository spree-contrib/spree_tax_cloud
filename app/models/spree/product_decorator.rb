Spree::Product.class_eval do
  validates_format_of :tax_cloud_tic, with: /\A\d{5}\z/, message: Spree.t(:standard_taxcloud_tic)

  # Use the store-default TaxCloud product TIC if none is defined for this product
  def tax_cloud_tic
    read_attribute(:tax_cloud_tic) || Spree::Config.taxcloud_default_product_tic
  end
  
  # Empty strings are written as nil (which avoids the format validation)
  def tax_cloud_tic=(tic)
    write_attribute(:tax_cloud_tic, tic.present? ? tic : nil)
  end
end
