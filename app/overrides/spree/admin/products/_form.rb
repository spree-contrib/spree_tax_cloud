Deface::Override.new(
  virtual_path: "spree/admin/products/_form",
  name: "add tic to admin product edit",
  insert_after: "[data-hook='admin_product_form_tax_category']",
  partial: "spree/admin/products/edit_tax_cloud_tic"
)
