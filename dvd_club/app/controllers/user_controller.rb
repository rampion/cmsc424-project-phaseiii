class UserController < ApplicationController
  layout 'standard'
  before_filter :check_session
  def index
    @dvds = Dvd.find(session[:cart] ||= [])
  end
  def add_to_cart
    if request.get?
      redirect_to :action => 'index' 
    else
      dvd = Dvd.find(request[:id].to_i)
      session[:cart] ||= []
      if @customer.overdrawn?
        flash[:notice] = "Sorry, your account is currently overdrawn"
        return
      elsif dvd.copies == 0
        flash[:notice] = "Sorry, this title is out of stock"
        return
      elsif session[:cart].include? dvd.id
        flash[:notice] = "Sorry, but this title is already in your cart"
        return
      end
      session[:cart] << dvd.id
      flash[:notice] = "Your DVD has been added to your shopping cart"
    end
  end
  def checkout
    if request.get?
      redirect_to :action => 'index' 
    else
      total = 0.0
      total_count = 0
      order = (request[:checkout] || []).map do |dvd_id, count|
        dvd = Dvd.find(dvd_id)
        count = count.to_i
        total_count += count
        if dvd.copies < count
          flash[:notice] = "Sorry, #{dvd.title} (#{dvd.year}) is in insufficient stock (there are only #{dvd.copies} copies)"
          return
        end
        total += dvd.sale_price * count
        [ dvd, count ]
      end
      if total_count == 0
        flash[:notice] = "Sorry, you can't check out with an empty cart"
        return
      elsif total + @customer.balance > @customer.credit_limit
        flash[:notice] = "Sorry, this order ($#{'%.2f'% total}) totalwould go over your credit limit"
        return
      end
      order.each do |dvd, count|
        count.times do 
          @customer.purchases.create('dvd_id' => dvd.id, 'sale_price' => dvd.sale_price, 'date_purchased' => Date.today )
        end
      end
      @customer.balance += total
      @customer.save
      flash[:notice] = "Your DVDs will be shipped shortly"
      session[:cart] = nil
    end
  end
  def rent
    if request.get?
      redirect_to :action => 'index' 
    else
      dvd = Dvd.find(request[:id].to_i)
      if @customer.overdrawn?
        flash[:notice] = "Sorry, your account is currently overdrawn"
        return
      elsif @customer.over_monthly_limit?
        flash[:notice] = "Sorry, you've already rented your allotment of DVDs for the month"
        return
      elsif @customer.over_concurrent_limit?
        flash[:notice] = "Sorry, you've already got as many DVDs rented at once as you can"
        return
      elsif dvd.copies == 0
        flash[:notice] = "Sorry, this title is out of stock"
        return
      end
      @customer.rentals.create( 'dvd_id' => dvd.id, 'date_rented' => Date.today )
      @customer.save
      flash[:notice] = "Your DVD will be shipped shortly"
    end
  end
  def search
    if request.get?
      redirect_to :action => 'index' 
    else
      sql_re = lambda { |str| str.downcase.gsub(/^|$/, '%').gsub(/[^a-z]+/, '%') }
      join = ['dvds d']
      where = []
      subs = []
      having = []
      search = request[:search]
      @dvds = []
      unless search[:title].empty?
        where << 'd.title like ?'
        subs << sql_re[search[:title]]
      end
      unless search[:year_range].empty?
        if search[:year_range].strip =~ /^\d{4}$/
          where << 'd.year = ?'
          subs << $&.to_i
        elsif search[:year_range].strip =~ /^(\d{4})\s*(?:\s|[:-]+)\s*(\d{4})$/
          where << '? <= d.year' << 'd.year <= ?'
          subs << $1.to_i << $2.to_i
        else
          flash[:notice] ||= "I'm sorry, I couldn't understand your date range, try 1985 or 1982-1984"
          return
        end
      end
      unless search[:featuring].empty?
        join << 'INNER JOIN appeared_in ai ON (d.id = ai.dvd_id)'
        join << 'INNER JOIN artists aai ON (ai.artist_id = aai.id)'
        where << 'aai.name like ?'
        subs <<  sql_re[search[:featuring]]
      end
      unless search[:director].empty?
        join << 'INNER JOIN directed dd ON (d.id = dd.dvd_id)'
        join << 'INNER JOIN artists add ON (dd.artist_id = add.id)'
        where << 'add.name like ?'
        subs <<  sql_re[search[:director]]
      end
      unless search[:producer].empty?
        join << 'INNER JOIN produced pd ON (d.id = pd.dvd_id)'
        join << 'INNER JOIN artists apd ON (pd.artist_id = apd.id)'
        where << 'apd.name like ?'
        subs <<  sql_re[search[:producer]]
      end
      unless search[:genre].empty?
        join << 'INNER JOIN dvds_genres dg ON (d.id = dg.dvd_id)'
        join << 'INNER JOIN genres g ON (dg.genre_id = g.id)'
        where << 'g.name like ?'
        subs <<  sql_re[search[:genre]]
      end
      unless search[:price_range].empty?
        price_re = /\$?(\d+(?:,\d{3})*(?:\.\d\d)?)/
        if search[:price_range].strip =~ /^#{price_re}$/
          where << 'd.sale_price = ?'
          subs << $1.gsub(',','').to_f
        elsif search[:price_range].strip =~ /^#{price_re}\s*(?:\s|[-:]+)\s*#{price_re}$/
          where << '? <= d.sale_price' << 'd.sale_price <= ?'
          subs << $1.to_f << $2.to_f
        else
          flash[:notice] ||= "I'm sorry, I couldn't understand your price range, try $19.85 or $19-$25.35"
          return
        end
      end
      unless search[:exclude_rentals] == "0"
        join << 'LEFT JOIN rentals rs ON (d.id = rs.dvd_id) '
        where << '(rs.customer_id IS NULL OR rs.customer_id = ?)'
        subs << @customer.id
        having << 'COUNT(rs.customer_id) = 0'
      end
      unless search[:exclude_purchases] == "0"
        join << 'LEFT JOIN purchases ps ON (d.id = ps.dvd_id) '
        where << '(ps.customer_id IS NULL OR ps.customer_id = ?)'
        subs << @customer.id
        having << 'COUNT(ps.customer_id) = 0'
      end
      
      query = 'SELECT d.* FROM ' + join.join(' ') 
      unless where.empty?
        query << ' WHERE ' << where.join(' AND ')
      end
      query << ' GROUP BY d.id'
      unless having.empty?
        query << ' HAVING '
        query << having.join(' AND ')
      end
      #@query = query
      #@subs = subs
      @dvds = Dvd.find_by_sql([ query, *subs ])
    end
  end
  def drop
    if request.get?
      redirect_to :action => 'index' 
    elsif (@customer.balance > 0)
        flash[:notice] = "Sorry, you can't do that until you pay off your account balance"
        #redirect_to :action => 'index'
    else
      Customer.delete(@customer.id)
      flash[:notice] = "The account was deleted"
      reset_session
      redirect_to :controller => 'welcome'
    end
  end
  private
    def check_session
      flash[:notice] = nil
      unless session[:customer_id] and (@customer = Customer.find(session[:customer_id]) rescue nil)
        redirect_to :controller => 'welcome'
      end
    end
end
