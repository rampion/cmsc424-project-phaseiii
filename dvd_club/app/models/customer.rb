class Customer < ActiveRecord::Base
  has_many :purchases
  has_and_belongs_to_many :dvds_purchased, :class_name => 'Dvd', :join_table => :purchases 
  has_and_belongs_to_many :dvds_owned, :class_name => 'Dvd', :join_table => :purchases, :conditions => { :date_returned => nil }
  has_many :rentals
  has_and_belongs_to_many :dvds_rented, :class_name => 'Dvd', :join_table => :rentals
  has_and_belongs_to_many :dvds_currently_rented, :class_name => 'Dvd', :join_table => :rentals, :conditions => { :date_returned => nil }
  has_many :payments
  belongs_to :rental_plan
  def validate
    unless self.credit_limit and self.credit_limit >= 0
      errors.add_to_base("Customer must have non-negative credit limit")
    end
  end
  def overdrawn?
    self.balance >= self.credit_limit
  end
  def over_monthly_limit?
    return false if self.rental_plan.dvds_per_month.nil?
    today = Date.today
    month = today - today.mday.days + 1
    rentals_this_month = self.rentals.find(:all, :conditions => ['date_returned >= ? OR date_rented >= ?', month, month])
    return rentals_this_month.size >= self.rental_plan.dvds_per_month
  end
  def over_concurrent_limit?
    still_out = self.rentals.find(:all, :conditions => 'date_returned IS NULL')
    return still_out.size >= self.rental_plan.max_rented_out
  end
end
