namespace :admin do
  desc "Ship DVDs; ship all rentals and purchases"
  task(:ship_dvds => :environment) do
    unshipped_purchases = Purchase.find(:all, :conditions => { :date_shipped => nil }) 
    Purchase.update( unshipped_purchases, Array.new(unshipped_purchases.size, { :date_shipped => Date.today } ))
    unshipped_rentals = Rental.find(:all, :conditions => { :date_shipped => nil })
    Rental.update( unshipped_rentals , Array.new(unshipped_rentals.size, { :date_shipped => Date.today } ))
  end
  desc "Drop DVD; mark a given DVD as no longer available (use TITLE=<dvd title> YEAR=<dvd year>)"
  task(:drop_dvd => :environment) do 
    unless title = ENV['TITLE']
      STDERR.puts "TITLE environment variable must be set"
      break
    end
    unless year = ENV['YEAR']
      STDERR.puts "YEAR environment variable must be set"
      break
    end
    dvds = Dvd.find(:all, :conditions => { :title => title, :year => year.to_i } )
    if dvds.empty?
      STDERR.puts "Unable to find #{title} (#{year})"
      break
    end
    Dvd.update( dvds, Array.new(dvds.size, {:is_discontinued => true}) )
  end
  desc "Mark a rental DVD as returned (use RENTAL_ID=<rental-id>)"
  task(:return_rental => :environment) do
    unless rental_id = ENV['RENTAL_ID']
      STDERR.puts "RENTAL_ID environment variable must be set"
      break
    end
    begin
      rental = Rental.update(rental_id.to_i, { :date_returned => Date.today })
      rental.dvd.copies += 1
      rental.save
    rescue ActiveRecord::RecordNotFound
      STDERR.puts "Unable to find rental #{rental_id}"
      break
    end
  end
  desc "Mark a purchased DVD as returned if it's within the 90 day window (use PURCHASE_ID=<purchase-id>)"
  task(:return_purchase => :environment) do
    unless purchase_id = ENV['PURCHASE_ID']
      STDERR.puts "PURCHASE_ID environment variable must be set"
      break
    end
    begin
      purchase = Purchase.find(purchase_id.to_i)
      if purchase.date_shipped + 90.days < Date.today
        STDERR.puts "Cannot return - past 90 day mark"
        break
      end
      purchase.date_returned = Date.today
      purchase.dvd.copies += 1
      purchase.customer.balance -= purchase.sale_price
      purchase.save
    rescue ActiveRecord::RecordNotFound
      STDERR.puts "Unable to find purchase #{purchase_id}"
      break
    end
  end
  desc "Receive a payment from a customer (use CUSTOMER_ID=<customer-id> and AMOUNT=<amount>)"
  task(:receive_payment => :environment) do
    unless customer_id = ENV['CUSTOMER_ID'] 
      STDERR.puts "CUSTOMER_ID environment variable must be set"
      break
    end
    unless amount = ENV['AMOUNT']
      STDERR.puts "AMOUNT environment variable must be set"
      break
    end
    unless amount.to_f >= 0
      STDERR.puts "AMOUNT must be >= 0"
      break
    end
    begin 
      customer = Customer.find(customer_id.to_i)
      customer.payments << Payment.create(:date_paid => Date.today, :amount => amount.to_f)
      customer.balance += amount.to_f
      customer.save
    rescue ActiveRecord::RecordNotFound
      STDERR.puts "Unable to find customer #{customer_id}"
      break
    end
  end
  desc "Generate bills for all members with outstanding balances  (printed to screen)"
  task(:generate_bills => :environment) do
    now = Date.today
    Customer.find(:all, :conditions => 'balance > 0').each do |customer|
      prior_balance = customer.balance
      purchases = Purchase.find(:all, :conditions => [ "date_purchased > ?", customer.last_bill_end_date ] )
      returns = Purchase.find(:all, :conditions => [ "date_returned > ?", customer.last_bill_end_date ] )
      payments = Payment.find(:all, :conditions => [ "date_paid > ?", customer.last_bill_end_date ] )
      prior_balance -= purchases.inject(0.0) { |sum,purchase| sum + purchase.sale_price }
      prior_balance += returns.inject(0.0) { |sum,a_return| sum + a_return.sale_price }

      puts "ID: #{customer.id}"
      puts customer.name
      puts "Prior Bill Date: #{customer.last_bill_end_date}"
      puts "Prior Balance: $%.2f" % prior_balance

      items = purchases.map { |a_purchase|  [a_purchase.date_purchased, :purchase, a_purchase] } +
              returns.map { |a_return|      [a_return.date_returned, :return, a_return] } +
              payments.map { |a_payment|    [a_payment.date_paid, :payment, a_payment] }

      date = customer.date_subscribed + customer.plan.billing_cycle_length
      while (date <= now)
        items << [date, :dues, nil ] if (customer.last_bill_end_date < date)
        date += customer.plan.billing_cycle_length
      end

      items.sort do |date,type,item|
        print "#{date}\t#{type}\t"
        case type
        when :dues
          puts "\t\t+$%.2f" % customer.plan.rate
          customer.balance += customer.plan.rate
        when :payment 
          puts "\t\t-$%.2f" % item.amount
        when :purchase
          puts "#{item.dvd.title} #{item.dvd.year}\t+$#{ "%.2f" % item.sale_price }"
        when :return
          puts "#{item.dvd.title} #{item.dvd.year}\t-$#{ "%.2f" % item.sale_price }"
        end
      end

      puts "Bill Date: #{now}"
      puts "Balance: %.2f" % customer.balance

      customer.last_bill_end_date = now
      customer.save
      puts "-"*78
    end
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
    STDERR.puts "Removing 'new' status from DVDs"
    Dvd.find(:all, :conditions => { :is_new => true }).each do |dvd|
      dvd.is_new = false
      dvd.sale_price = dvd.list_price
      dvd.save
      STDERR.print "."
      STDERR.flush
    end
    STDERR.puts
    STDERR.puts "done"
  end
  desc "Loads new DVDs from given YAML file; give them the sale price for new DVDs (use INPUT=<filename>)"
  task(:add_new_dvd => :environment)  do 
    records = YAML::load(File.read(ENV['INPUT']))
    STDERR.puts "Adding DVDs"
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
      STDERR.print "."
      STDERR.flush
    end
    STDERR.puts
    STDERR.puts "#{records.size} new DVDs added"
  end
end
