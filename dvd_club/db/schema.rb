# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20090515151922) do

  create_table "appeared_in", :id => false, :force => true do |t|
    t.integer "artist_id", :null => false
    t.integer "dvd_id",    :null => false
  end

  create_table "artists", :force => true do |t|
    t.string "name", :null => false
  end

  create_table "artists_dvds", :id => false, :force => true do |t|
    t.integer "artist_id", :default => 0, :null => false
    t.integer "dvd_id",    :default => 0, :null => false
  end

  create_table "customers", :force => true do |t|
    t.datetime "date_subscribed",                                   :null => false
    t.integer  "rental_plan_id"
    t.string   "name",                                              :null => false
    t.string   "address",                                           :null => false
    t.string   "phone_number",                                      :null => false
    t.decimal  "credit_limit",       :precision => 63, :scale => 2, :null => false
    t.datetime "last_bill_end_date",                                :null => false
    t.decimal  "balance",            :precision => 63, :scale => 2, :null => false
  end

  create_table "customers_dvds", :id => false, :force => true do |t|
    t.integer  "customer_id", :default => 0, :null => false
    t.datetime "date",                       :null => false
    t.integer  "dvd_id"
  end

  create_table "directed", :id => false, :force => true do |t|
    t.integer "artist_id", :null => false
    t.integer "dvd_id",    :null => false
  end

  create_table "dvds", :force => true do |t|
    t.string  "title",                                          :null => false
    t.integer "year",                                           :null => false
    t.integer "copies",                                         :null => false
    t.boolean "is_new",                                         :null => false
    t.boolean "is_discontinued",                                :null => false
    t.decimal "list_price",      :precision => 63, :scale => 2, :null => false
    t.decimal "sale_price",      :precision => 63, :scale => 2, :null => false
  end

  create_table "dvds_genres", :id => false, :force => true do |t|
    t.integer "genre_id", :null => false
    t.integer "dvd_id",   :null => false
  end

  create_table "genres", :force => true do |t|
    t.string "name", :null => false
  end

  create_table "payments", :force => true do |t|
    t.integer  "customer_id"
    t.datetime "date_paid",                                  :null => false
    t.decimal  "amount",      :precision => 63, :scale => 2, :null => false
  end

  create_table "produced", :id => false, :force => true do |t|
    t.integer "artist_id", :null => false
    t.integer "dvd_id",    :null => false
  end

  create_table "purchases", :force => true do |t|
    t.integer  "customer_id"
    t.integer  "dvd_id"
    t.decimal  "sale_price",     :precision => 63, :scale => 2, :null => false
    t.datetime "date_purchased",                                :null => false
    t.datetime "date_shipped"
    t.datetime "date_returned"
  end

  create_table "rental_plans", :force => true do |t|
    t.decimal "rate",                 :precision => 63, :scale => 2, :null => false
    t.integer "billing_cycle_length",                                :null => false
    t.integer "max_rented_out",                                      :null => false
    t.integer "dvds_per_month"
  end

  create_table "rentals", :force => true do |t|
    t.integer  "customer_id"
    t.integer  "dvd_id"
    t.datetime "date_rented",   :null => false
    t.datetime "date_shipped"
    t.datetime "date_returned"
  end

end
