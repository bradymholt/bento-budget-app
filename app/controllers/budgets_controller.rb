class BudgetsController < ApplicationController
	respond_to :html, :json

	def index
    @envelopes = Envelope.with_groups(current_user_id) 
      .where(envelope_groups: { user_id: current_user_id })
    @budgets = Budget.where(:user_id => current_user_id)
    @budgets_by_envelope = Hash[@budgets.collect { |b| [b.envelope_id, b.amount]}]
    @budgets_by_envelope.default = 0.00
    @allocation_plans = AllocationPlan.where(:user_id => current_user_id).where.not(income_id: nil)
    @incomes = Income.where(:user_id => current_user_id)
    @total_monthly_income = @incomes.collect{|i| i.allocated_monthly}.reduce(:+)
    @total_allocated_monthly = @incomes.collect { |i| i.allocated_monthly }.reduce(:+)
    
    respond_with(@envelopes)
  end

  def update
      @budget = Budget.find_or_initialize_by(user_id: current_user_id, envelope_id:  params[:envelope_id])
      @budget.amount = params[:amount]
      if !@budget.valid?
        @budget.amount = 0
      end
      
      if @budget.save
        respond_to do |format|
          format.json { render :json => {:amount => @budget.amount} }
          format.html { redirect_to budgets_url }
        end
      else
         respond_with(@budget, :status => :unprocessable_entity)
      end
  end
end