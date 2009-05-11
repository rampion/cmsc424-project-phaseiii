class RentalPlan < ActiveRecord::Base
  has_many :customers
  validate do |plan|
    unless plan.rate >= 0
      errors.add_to_base("Rate must be greater or equal to $0 per billing cycle")
    end
    unless plan.billing_cycle_length > 0
      errors.add_to_base("Billing cycle length must be a positive number of months")
    end
    unless plan.max_rented_out >= 0
      errors.add_to_base("Concurrent rental limit must be a nonnegative number of DVDs")
    end
    unless plan.dvds_per_month.nil? or plan.dvds_per_month >= plan.max_rented_out
      errors.add_to_base("Monthly rental limit must be greater than concurrent rental limit")
    end
  end
end
