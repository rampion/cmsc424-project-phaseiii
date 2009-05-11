class Purchase < ActiveRecord::Base
  belongs_to :dvd
  belongs_to :customer
  validate do |purchase|
    unless purchase.sale_price >= 0
      errors.add_to_base("Sale price must be non-negative")
    end
    if purchase.date_shipped and (purchase.date_shipped < purchase.date_purchased)
      errors.add_to_base("Cannot be shipped until it has been purchased")
    end
    if purchase.date_returned and (not purchase.date_shipped or purchase.date_returned < purchase.date_shipped)
      errors.add_to_base("Cannot be returned until it has been shipped")
    end
  end
end
