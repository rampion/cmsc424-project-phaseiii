class WelcomeController < ApplicationController
  layout 'standard'
  def index
    flash[:notice] = nil
    # shouldn't need to do much
    if request.post?
      # POST: redirect to user/index
      customers = Customer.find(:all, :conditions => { :name => params[:customer][:name] }) rescue []
      if customers.empty?
        flash[:notice] = "Sorry, I couldn't find that user.  Do you mind trying again?"
      else
        session[:customer_id] = customers.first.id
        redirect_to :controller=> 'user'
      end
    end
  end
  def register
    # GET: give the form
    if request.get?
      @plans = RentalPlan.find(:all).map do |plan|
        label = "#{'%.2f'%plan.rate} every #{plan.billing_cycle_length} month(s),"+
                " #{plan.max_rented_out} DVDs at a time"
        if plan.dvds_per_month
          label << ", #{plan.dvds_per_month} total per month"
        end
        [ label, plan.id ]
      end
    end
    if request.post?
      # POST: create new customer (TODO)
      if params[:customer][:name].empty?
        flash[:notice] = "Sorry, please enter a name."
      elsif params[:customer][:address].empty?
        flash[:notice] = "Sorry, please enter an address."
      elsif params[:customer][:phone_number].empty?
        flash[:notice] = "Sorry, please enter a phone number."
      elsif not Customer.find(:all, :conditions => { :name => params[:customer][:name] }).empty?
        flash[:notice] = "Sorry, do you mind altering your name a little bit?"
      elsif not (rental_plan = RentalPlan.find(params[:customer][:plan_id]) rescue nil)
        flash[:notice] = "Sorry, I couldn't find that rental plan, do you mind trying again?"
      elsif /^\$?(\d+(?:,\d{3})*(?:\.\d\d)?)$/ !~ params[:customer][:credit_limit]
        flash[:notice] = "Sorry, I couldn't recognize that credit limit.  Do you mind trying again?"
      else
        customer = Customer.create( 
              :name => params[:customer][:name],
              :address => params[:customer][:address],
              :phone_number => params[:customer][:phone_number],
              :credit_limit => $1.gsub(',','').to_f,
              :last_bill_end_date => Date.today,
              :date_subscribed => Date.today,
              :balance => rental_plan.rate,
              :rental_plan => rental_plan
        )
        customer.save!
        session[:customer_id] = customer.id
        # redirect to login 
        redirect_to :controller => 'user'
      end
    end
  end
end
