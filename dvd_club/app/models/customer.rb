class Customer < ActiveRecord::Base
  has_many :purchases
  has_and_belongs_to_many :dvds_purchased, :class_name => :Dvd, :join_table => :purchases 
  has_and_belongs_to_many :dvds_owned, :class_name => :Dvd, :join_table => :purchases, :conditions => { :date_returned => nil }
  has_many :rentals
  has_and_belongs_to_many :dvds_rented, :class_name => :Dvd, :join_table => :rentals
  has_and_belongs_to_many :dvds_currently_rented, :class_name => :Dvd, :join_table => :rentals, :conditions => { :date_returned => nil }
  has_many :payments
  belongs_to :rental_plan
  validate do |customer|
    unless customer.credit_limit >= 0
      errors.add_to_base("Customer must have non-negative credit limit")
    end
    unless customer.credit_limit >= customer.balance
      errors.add_to_base("Customer balance must not exceed credit limit")
    end
  end
end
