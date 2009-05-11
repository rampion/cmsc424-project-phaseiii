class Rental < ActiveRecord::Base
  belongs_to :dvd
  belongs_to :customer
  validate do |rental|
    if rental.date_shipped and (rental.date_shipped < rental.date_rented)
      errors.add_to_base("Cannot be shipped until it has been rented")
    end
    if rental.date_returned and (not rental.date_shipped or rental.date_returned < rental.date_shipped)
      errors.add_to_base("Cannot be returned until it has been shipped")
    end
  end
end
