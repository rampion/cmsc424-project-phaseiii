class CreateTables < ActiveRecord::Migration
  def self.up
    create_table :rental_plans do |t|
      t.decimal :rate, :precision => 63, :scale => 2, :null => false
      t.integer :billing_cycle_length, :null => false
      t.integer :max_rented_out, :null => false
      t.integer :dvds_per_month, :null => false
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
  end

  def self.down
    drop_table :customers
    drop_table :rental_plans
  end
end
