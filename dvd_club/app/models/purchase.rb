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
    if purchase.date_returned and purchase.date_shipped and purchase.date_shipped + 90.days < purchase.date_returned )
      errors.add_to_base("Cannot be returned more than 90 days after purchase")
    end
  end
end
