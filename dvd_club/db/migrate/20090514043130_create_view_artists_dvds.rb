class CreateViewArtistsDvds < ActiveRecord::Migration
  def self.up
    execute <<-SQL
      CREATE VIEW artists_dvds AS 
        (SELECT * FROM appeared_in) UNION ALL
        (SELECT * FROM directed) UNION ALL
        (SELECT * FROM produced)
      ;
    SQL
  end

  def self.down
    execute <<-SQL
      DROP VIEW artists_dvds;
    SQL
  end
end
