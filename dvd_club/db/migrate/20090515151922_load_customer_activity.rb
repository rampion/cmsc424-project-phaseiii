class LoadCustomerActivity < ActiveRecord::Migration
  def self.up
    File.read( __FILE__.sub(/\.rb$/, '.sql') ).split(";\n").each do |statement|
      execute statement
    end
  end

  def self.down
    %w{ customers payments purchases rentals }.each do |table|
      execute "DELETE FROM #{table}"
    end
  end
end
