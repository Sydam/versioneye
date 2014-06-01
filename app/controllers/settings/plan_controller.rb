class Settings::PlanController < ApplicationController

  before_filter :authenticate

  def index
    if current_user.plan.nil?
      current_user.plan = Plan.free_plan
      current_user.save
    end
    @plan = current_user.plan
  end

  def update
    @plan_name_id = params[:plan]
    user          = current_user
    stripe_token  = user.stripe_token
    customer_id   = user.stripe_customer_id
    customer      = nil
    if customer_id && stripe_token
      customer = StripeService.fetch_customer customer_id
    end
    if customer
      update_plan( user, customer, @plan_name_id )
      redirect_to settings_plans_path
    else
      flash[:info] = 'Please update your Credit Card information.'
      cookies.permanent.signed[:plan_selected] = @plan_name_id
      @billing_address = current_user.fetch_or_create_billing_address
      redirect_to settings_creditcard_path
    end
  end

  private

    def update_plan user, customer, plan_name_id
      customer.update_subscription( :plan => plan_name_id )
      user.plan = Plan.by_name_id plan_name_id
      if user.save
        SubscriptionMailer.update_subscription( user ).deliver
        flash[:success] = 'We updated your plan successfully.'
      else
        flash[:error] = 'Something went wrong. Please contact the VersionEye team.'
      end
    end

end
