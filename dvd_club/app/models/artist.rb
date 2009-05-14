class Artist < ActiveRecord::Base
  has_and_belongs_to_many :appearances, :class_name => 'Dvd', :join_table => :appeared_in
  has_and_belongs_to_many :directed_dvds, :class_name => 'Dvd', :join_table => :directed
  has_and_belongs_to_many :produced_dvds, :class_name => 'Dvd', :join_table => :produced
end
