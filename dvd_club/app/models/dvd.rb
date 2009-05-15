class Dvd < ActiveRecord::Base
  has_many :purchases
  has_and_belongs_to_many :purchasers, :class_name => 'Customer', :join_table => :purchases 
  has_and_belongs_to_many :owners, :class_name => 'Customer', :join_table => :purchases, :conditions => { :date_returned => nil }
  has_many :rentals
  has_and_belongs_to_many :renters, :class_name => 'Customer', :join_table => :rentals
  has_and_belongs_to_many :current_renters, :class_name => 'Customer', :join_table => :rentals, :conditions => { :date_returned => nil }
  has_and_belongs_to_many :stars, :class_name => 'Artist', :join_table => :appeared_in
  has_and_belongs_to_many :directors, :class_name => 'Artist', :join_table => :directed
  has_and_belongs_to_many :producers, :class_name => 'Artist', :join_table => :produced
  has_and_belongs_to_many :genres
  def title_year
    "#{title} (#{year})"
  end
  def validate 
    unless self.copies and self.copies >= 0
      errors.add_to_base("Copies in stock must be non-negative")
    end
    unless self.list_price and self.list_price >= 0
      errors.add_to_base("List price must be non-negative")
    end
    unless self.sale_price and self.sale_price >= 0
      errors.add_to_base("Sale price must be non-negative")
    end
  end
end
