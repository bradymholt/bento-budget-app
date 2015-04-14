class SubscriptionsController < ApplicationController
  protect_from_forgery :except => [:notify]
  skip_before_filter :authenticate_user!

  def index
    @user = current_user
  end

  def new
    if !current_user.is_trial_period_used
    else
    end
  end

  def check
    render :json => { :is_subscriber => current_user.is_subscriber }
  end

  def notify
    if !params[:custom].blank?
      SubscriptionNotification.create!(:params => params, 
      	:user_id => params[:custom], 
      	:transaction_type => params[:txn_type], 
      	:transaction_id => params[:txn_id] )
    end
    render :nothing => true

    #Documention: https://developer.paypal.com/webapps/developer/docs/classic/ipn/integration-guide/IPNandPDTVariables/
    #Examples: Parameters: {"txn_type"=>"subscr_signup", "subscr_id"=>"I-PYXFKN4VJJ9P", "last_name"=>"HOLT", "residence_country"=>"US", "mc_currency"=>"USD", "item_name"=>"Bento Budget Pro", "business"=>"brady.holt@gmail.com", "amount3"=>"5.00", "recurring"=>"1", "verify_sign"=>"AT0G1kK5dPUZ8YXtRS.hJ5EPC9aiAovgTTj3VFeBfcwJOQrcFgTgBm6K", "payer_status"=>"unverified", "payer_email"=>"bholt@csi.net", "first_name"=>"KATIE", "receiver_email"=>"brady.holt@gmail.com", "payer_id"=>"YHNSAS5GP898W", "reattempt"=>"1", "item_number"=>"3438298432", "subscr_date"=>"14:28:03 Oct 10, 2013 PDT", "btn_id"=>"71998596", "custom"=>"2", "charset"=>"windows-1252", "notify_version"=>"3.7", "period3"=>"1 M", "mc_amount3"=>"5.00", "ipn_track_id"=>"29d2621df2db2"}
  end

  end