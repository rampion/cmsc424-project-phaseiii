class Payment < ActiveRecord::Base
  def validate
    unless self.amount >= 0
      errors.add_to_base("Payment amount must be greater than or equal to zero")
    end
  end
end
