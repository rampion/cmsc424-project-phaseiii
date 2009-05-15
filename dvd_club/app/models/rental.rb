class Rental < ActiveRecord::Base
  belongs_to :dvd
  belongs_to :customer
  def validate
    unless date_rented
      errors.add_to_base("Date rented may not be null")
    end
    if self.date_shipped and (self.date_shipped < self.date_rented)
      errors.add_to_base("Cannot be shipped until it has been rented")
    end
    if self.date_returned and (not self.date_shipped or self.date_returned < self.date_shipped)
      errors.add_to_base("Cannot be returned until it has been shipped")
    end
  end
end
