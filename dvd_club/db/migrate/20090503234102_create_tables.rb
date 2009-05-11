require 'yaml'
class CreateTables < ActiveRecord::Migration
  def self.up
    create_table :rental_plans do |t|
      t.decimal :rate, :precision => 63, :scale => 2, :null => false
      t.integer :billing_cycle_length, :null => false
      t.integer :max_rented_out, :null => false
      t.integer :dvds_per_month
    end
    create_table :customers do |t|
      t.timestamp :date_subscribed, :null => false
      t.references :rental_plan
      t.string :name, :null => false
      t.string :address, :null => false
      t.string :phone_number, :null => false
      t.decimal :credit_limit, :precision => 63, :scale => 2, :null => false
      t.timestamp :last_bill_end_date, :null => false
      t.decimal :balance, :precision => 63, :scale => 2, :null => false
    end
    create_table :dvds do |t|
      t.string :title, :null => false
      t.integer :year, :null => false
      t.integer :copies, :null => false
      t.boolean :is_new, :null => false
      t.boolean :is_discontinued, :null => false
      t.decimal :list_price, :null => false, :precision => 63, :scale => 2
      t.decimal :sale_price, :null => false, :precision => 63, :scale => 2
    end
    create_table :artists do |t|
      t.string :name, :null => false
    end
    create_table :genres do |t|
      t.string :name, :null => false
    end
    create_table :appeared_in do |t|
      t.references :artist
      t.references :dvd
    end
    create_table :directed do |t|
      t.references :artist
      t.references :dvd
    end
    create_table :produced do |t|
      t.references :artist
      t.references :dvd
    end
    create_table :dvd_genre do |t|
      t.references :genre
      t.references :dvd
    end
    create_table :purchases do |t|
      t.references :customer
      t.references :dvd
      t.decimal :sale_price, :null => false, :precision => 63, :scale => 2
      t.timestamp :date_purchased, :null => false
      t.timestamp :date_shipped
      t.timestamp :date_returned
    end
    create_table :rentals do |t|
      t.references :customer
      t.references :dvd
      t.timestamp :date_rented, :null => false
      t.timestamp :date_shipped
      t.timestamp :date_returned
    end
    create_table :payments do |t|
      t.references :customer
      t.timestamp :date_paid, :null => false
      t.decimal :amount, :null => false, :precision => 63, :scale => 2
    end

    # dump table names to a file
    File.open(__FILE__ + '.yaml', 'w') { |f| f.puts YAML::dump(@new_tables) }
  end
  def self.down
    # grab table names from the file
    @new_tables = YAML::load(File.read(__FILE__ + '.yaml'))
    @new_tables.reverse.each { |table_name| drop_table table_name }
  end
  def self.create_table(table_name, options={})
    # save table names as we create them
    @new_tables ||= []
    @new_tables << table_name
    super
  end
end
