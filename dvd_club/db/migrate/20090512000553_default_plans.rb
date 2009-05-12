class DefaultPlans < ActiveRecord::Migration
  def self.up
=begin
Rental Plans: Three plans will be available: * $3.99/month for 1 DVD at a time (2 DVDs total per 
month) * $19.95/month for 3 DVDs at a time (unlimited monthly rentals) * $9.98/month for 3 DVDs 
at a time (unlimited monthly rentals) if you pre-pay $119.70 for a year of membership 
=end
    RentalPlan.create(:rate => 3.99, :billing_cycle_length => 1, :max_rented_out => 1, :dvds_per_month => 2)
    RentalPlan.create(:rate => 19.95, :billing_cycle_length => 1, :max_rented_out => 3)
    RentalPlan.create(:rate => 119.70, :billing_cycle_length => 12, :max_rented_out => 3)
  end

  def self.down
    RentalPlan.delete_all
  end
end
