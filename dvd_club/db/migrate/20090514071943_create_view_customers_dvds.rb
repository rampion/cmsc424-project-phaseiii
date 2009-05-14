class CreateViewCustomersDvds < ActiveRecord::Migration
  def self.up
    execute <<-SQL
      CREATE VIEW customers_dvds AS
      (SELECT c.id AS customer_id, p.date_purchased AS date, p.dvd_id
       FROM customers c INNER JOIN purchases p ON (c.id = p.customer_id))
      UNION ALL
      (SELECT c.id AS customer_id, r.date_rented AS date, r.dvd_id
       FROM customers c INNER JOIN rentals r ON (c.id = r.customer_id))
      ;
    SQL
  end

  def self.down
    execute <<-SQL
      DROP VIEW customers_dvds;
    SQL
  end
end
