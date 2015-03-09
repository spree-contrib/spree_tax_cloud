Spree::StockLocation.class_eval do
  scope :valid, -> { active.where("city IS NOT NULL and state_id IS NOT NULL") }
end
