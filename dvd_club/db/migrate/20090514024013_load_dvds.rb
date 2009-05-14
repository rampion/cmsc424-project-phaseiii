class LoadDvds < ActiveRecord::Migration
  def self.up
    File.read( __FILE__.sub(/\.rb$/, '.sql') ).split(";\n").each do |statement|
      execute statement
    end
    #system("mysql --user root dvd_club_development < #{__FILE__.sub('.rb', '.sql')}")
  end

  def self.down
    %w{ dvds artists genres appeared_in directed produced dvds_genres }.each do |table|
      execute "DELETE FROM #{table}"
    end
  end
end
