class Purchase < ActiveRecord::Base
  belongs_to :dvd
  belongs_to :customer
  protected
  def validate
    unless self.sale_price and self.sale_price >= 0
      errors.add_to_base("Sale price must be non-negative")
    end
    unless self.date_purchased
      errors.add_to_base("Date purchased may not be null")
    end
    if self.date_shipped and (self.date_shipped < self.date_purchased)
      errors.add_to_base("Cannot be shipped until it has been purchased")
    end
    if self.date_returned and (not self.date_shipped or self.date_returned < self.date_shipped)
      errors.add_to_base("Cannot be returned until it has been shipped")
    end
    if self.date_returned and self.date_shipped and self.date_shipped + 90.days < self.date_returned
      errors.add_to_base("Cannot be returned more than 90 days after purchase")
    end
  end
end
