namespace :admin do
  desc "Ship DVDs; ship all rentals and purchases"
  task(:ship_dvds => :environment) do
    Purchase.update( Purchase.find(:all, :conditions => { :date_shipped => nil }), { :date_shipped => Date.today } )
    Rental.update( Rental.find(:all, :conditions => { :date_shipped => nil }), { :date_shipped => Date.today } )
  end
  desc "Drop DVD; mark a given DVD as no longer available (use TITLE=<dvd title> YEAR=<dvd year>)"
  task(:drop_dvd => :environment) do 
    unless title = ENV['TITLE']
      puts "TITLE environment variable must be set"
      break
    end
    unless year = ENV['YEAR']
      puts "YEAR environment variable must be set"
      break
    end
    Dvd.update(14, { :is_discontinued => true } )
=begin
    dvds = Dvd.find(:all, :conditions => { :title => title, :year => year.to_i } )
    if dvds.empty?
      puts "Unable to find #{title} (#{year})"
      break
    end
    dvds.each do |dvd|
      dvd.is_discontinued = true
      dvd.save
    end
=end
  end
  desc "Generate bills for all members with outstanding balances  (printed to screen)"
  task(:generate_bills => :environment) do
  end
  desc "Generate unpopularity report (use LIMIT=<count> START=<start date> END=<end date>, OVERLAP=<overlap>), "+
       "apply discount, and print to screen"
  task(:generate_unpopularity_report => :environment) do
=begin
    Unpopularity Report: Occasionally the club generates a list of the m DVDs for a particular category 
    that have had the poorest sales over a speciﬁed range of dates. These DVDs are given a sales price of 
    20% oﬀ of the list price. Announcement letters should be sent to all members who are likely to enjoy 
    these DVDs; that is, all members who have purchased or rented DVDs of the same type (same artists 
    or theme) of movies, at least n times in the past year AND have purchased/rented any DVD in the 
    past six months. 
=end
    ActiveRecord::Base.module_eval do 
      start_date = ENV['START']   ? Date.parse(ENV['START'])  : Date.today - 1.year
      stop_date  = ENV['END']     ? Date.parse(ENV['END'])    : Date.today
      limit      = ENV['LIMIT']   ? ENV['LIMIT'].to_i         : 10
      overlap    = ENV['OVERLAP'] ? ENV['OVERLAP'].to_i       : 55

      STDERR.puts "finding unpopular DVDs"
      # find which DVDs were unpopular
      connection.execute(sanitize_sql([<<-SQL, start_date, stop_date, limit ]))
        CREATE TEMPORARY TABLE unpopular_dvds
          SELECT d.id AS dvd_id
          FROM dvds d LEFT JOIN purchases p ON (d.id = p.dvd_id)
          WHERE d.is_discontinued = 0
            AND (p.date_purchased IS NULL OR (p.date_purchased >= ? AND p.date_purchased <= ?))
          GROUP BY d.id
          ORDER BY COUNT(p.id) ASC
          LIMIT ?  
      SQL

      STDERR.puts "finding genres used by unpopular DVDs"
      # find out which genres matched the unpopular DVDs
      connection.execute(<<-SQL)
        CREATE TEMPORARY TABLE unpopular_genres
          SELECT dg.genre_id
          FROM unpopular_dvds ud INNER JOIN dvds_genres dg USING (dvd_id)
      SQL

      STDERR.puts "finding artists featured in unpopular DVDs"
      # find which artist matched the unpopular DVDs
      connection.execute(<<-SQL)
        CREATE TEMPORARY TABLE unpopular_artists
          SELECT ad.artist_id
          FROM unpopular_dvds ud INNER JOIN artists_dvds ad USING (dvd_id)
      SQL

      STDERR.puts "finding DVDs similar to the unpopular DVDs"
      # find which DVDs are similar to the unpopular DVDs
      connection.execute(<<-SQL)
        CREATE TEMPORARY TABLE similar_dvds
          ( SELECT dvd_id FROM dvds_genres INNER JOIN unpopular_genres USING (genre_id)) 
        UNION ALL 
          ( SELECT dvd_id FROM artists_dvds INNER JOIN unpopular_artists USING (artist_id))
      SQL

      STDERR.puts "finding customers active in the last 6 months"
      # find which customers rented or purchased anything in the past 6 months
      connection.execute(<<-SQL)
        CREATE TEMPORARY TABLE recent_customers
          SELECT customer_id
          FROM customers_dvds
          WHERE date >= TIMESTAMPADD(MONTH,-6,NOW())
          GROUP BY customer_id
      SQL

      STDERR.puts "finding active customers that have rented or purchased enough DVDs similar to the unpopular in the past year"
      # find which recent customers rented or purchased something similar to the
      # unpopular DVDs in the past year
      potentially_interested = Customer.find_by_sql([ <<-SQL, overlap ])
        SELECT c.*
        FROM similar_dvds sd  INNER JOIN customers_dvds cd USING (dvd_id)
                              INNER JOIN recent_customers rc USING (customer_id)
                              INNER JOIN customers c ON (c.id = rc.customer_id)
        WHERE cd.date >= TIMESTAMPADD(YEAR,-1,NOW())
        GROUP BY rc.customer_id
        HAVING COUNT(sd.dvd_id) > ?
      SQL
      unpopular_dvds = Dvd.find_by_sql(<<-SQL)
        SELECT d.* FROM unpopular_dvds ud INNER JOIN dvds d ON (ud.dvd_id = d.id)
      SQL
      
      puts "Send Announcements to:"
      potentially_interested.each do |customer|
        puts "\t#{customer.name}"
      end
      puts "-"*78
      puts "of sale prices for these DVDs"
      unpopular_dvds.each do |dvd|
        dvd.sale_price = 0.8 * dvd.list_price
        dvd.save
        puts "\t%s\t$%.2f" % [ dvd.title, dvd.sale_price ]
      end
    end
  end
  desc "Age off new DVDs; remove their sale price"
  task(:age_off_new_dvd => :environment) do
    puts "Removing 'new' status from DVDs"
    Dvd.find(:all, :conditions => { :is_new => true }).each do |dvd|
      dvd.is_new = false
      dvd.sale_price = dvd.list_price
      dvd.save
      print "."
      STDOUT.flush
    end
    puts
    puts "done"
  end
  desc "Loads new DVDs from given YAML file; give them the sale price for new DVDs (use INPUT=<filename>)"
  task(:add_new_dvd => :environment)  do 
    records = YAML::load(File.read(ENV['INPUT']))
    puts "Adding DVDs"
    records.each do |record|
      dvd = Dvd.create( 
        :title => record[:title], 
        :year => record[:year], 
        :copies => record[:copies], 
        :is_new => true,
        :is_discontinued => false,
        :list_price => record[:list_price],
        :sale_price => record[:list_price] * 0.90
      )
      #p :title =>  record[:title], :dvd => dvd
      record[:stars].each do |artist_name|
        artist = Artist.find_or_create_by_name(artist_name)
        #p :star => artist_name, :artist => artist
        dvd.stars << artist
      end
      record[:directors].each do |director_name|
        artist = Artist.find_or_create_by_name(director_name)
        #p :director => director_name, :artist => artist
        dvd.directors << artist
      end
      record[:producers].each do |producer_name|
        artist = Artist.find_or_create_by_name(producer_name)
        #p :producer => producer_name, :artist => artist
        dvd.producers << artist
      end
      record[:genres].each do |genre_name|
        genre = Genre.find_or_create_by_name(genre_name)
        #p :genre_name => genre_name, :genre => genre
        dvd.genres << genre
      end
      dvd.save
      print "."
      STDOUT.flush
    end
    puts
    puts "#{records.size} new DVDs added"
  end
end
