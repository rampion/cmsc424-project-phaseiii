class DefaultPlans < ActiveRecord::Migration
  def self.up
    # Rental Plans: Three plans will be available: 
    # * $3.99/month for 1 DVD at a time (2 DVDs total per month) 
    RentalPlan.create(:rate => 3.99, :billing_cycle_length => 1, :max_rented_out => 1, :dvds_per_month => 2)
    # * $19.95/month for 3 DVDs at a time (unlimited monthly rentals) 
    RentalPlan.create(:rate => 19.95, :billing_cycle_length => 1, :max_rented_out => 3)
    # * $9.98/month for 3 DVDs at a time (unlimited monthly rentals) 
    #   if you pre-pay $119.70 for a year of membership 
    RentalPlan.create(:rate => 119.70, :billing_cycle_length => 12, :max_rented_out => 3)
  end

  def self.down
    Purchase.delete_all
    Rental.delete_all
    Payment.delete_all
    Customer.delete_all
    RentalPlan.delete_all
  end
end
