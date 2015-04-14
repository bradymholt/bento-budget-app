 class IncomesController < ApplicationController 
    before_action :set_income, :only => [:edit, :update, :delete, :destroy]
    before_action :set_ancillary, :only => [:new, :edit]
    respond_to :html, :json

    def new
      respond_with(@income = Income.new)
    end

    def create
       @income = Income.new(income_params)
       @income.user_id = current_user_id

      if @income.save 
        respond_to do |format|
           format.json { render :json => { :success => { :navigate => { :href => budgets_path } } } }
           format.html { redirect_to budgets_path }
        end
      else
        set_ancillary
        respond_with(@income, :status => :unprocessable_entity)
      end
    end

  	def edit
     respond_with(@income)
    end

     def update
      if @income.update_attributes(income_params)
        respond_to do |format|
           format.json { render :json => { :success => { :navigate => { :href => budgets_path } } } }
           format.html { redirect_to budgets_path }
        end
      else 
         set_ancillary
         respond_with(@income, :status => :unprocessable_entity)
      end
    end

    def delete
    end

    def destroy
      @income.destroy
      respond_to do |format|
        format.json { render :json => { :success => { :navigate => { :href => budgets_path } } } }
        format.html { redirect_to budgets_path }
      end
    end

    private
    def set_income
      @income = Income.where(:user_id => current_user_id).find(params[:id])
    end

    def set_ancillary
      @income_frequencies = IncomeFrequency.all
      @allocation_methods = AllocationMethod.all
      @other_incomes = Income.where({ :user_id => current_user_id, :allocation_method_grouped_with_income_id => nil}).where.not(id: params[:id])
    end

    def income_params
      params.require(:income).permit(:name, :amount, :income_frequency_id, :allocation_method_id, :allocation_method_grouped_with_income_id)
    end
end