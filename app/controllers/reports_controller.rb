class ReportsController < ApplicationController
  before_filter :force_subscription!

  def index
    if current_user.is_subscriber
  	 redirect_to :action => :envelope_spending
    end
  end

  def envelope_spending
  	@months_back = 3
   	@envelope_groups = EnvelopeGroup.with_envelopes(current_user_id).where(:user_id => current_user_id)
  end

  def envelope_spending_run
      @data = Reports.envelope_spending(current_user_id, params[:envelope_id], params[:months_back].to_i)
      render json: @data
  end

  def envelope_group_spending
    @months_back = 3
  end

  def envelope_group_spending_run
    @data = Reports.envelope_group_spending(current_user_id, params[:months_back].to_i)
    render json: @data
  end

  def funding_spending
    @months = Hash.new
    for i in 0..12
      current_date = (DateTime.now.beginning_of_month - i.months)
      @months[current_date.strftime('%B %Y')] = current_date.strftime('%Y-%m-%d');
    end
  end

  def funding_spending_run
    @data = Reports.funding_spending(current_user_id, params[:month])
    render partial: "funding_spending"
  end

  def recurring_transactions
     @months_back = 3
  end

  def recurring_transactions_run
    @data = Reports.recurring_transactions(current_user_id, params[:months_back].to_i)
    render partial: "recurring_transactions"
  end
end
