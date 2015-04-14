class AllocationPlansController < ApplicationController
	before_action :set_plan, only: [:edit, :update, :destroy]
 	respond_to :html, :json

 	def index
		@plans = AllocationPlan.where(:user_id => current_user_id)
		respond_with(@plans)
	end

  	def new
    	@plan = AllocationPlan.new
    end

    def create
		@plan = AllocationPlan.new(plan_params)
		@plan.user_id = current_user_id

		if @plan.save
			render :json => { :refresh => :page }
		else
			respond_with(@plan, :status => :unprocessable_entity)
		end  
	end

    def edit
    end

    def update
    	respond_to do |format|
	        if @plan.update(plan_params)
		        format.html { redirect_to budgets_path }
	        else
	        	format.html { render action: 'edit', :status => :unprocessable_entity }
	        end
	     end
    end

	def destroy
    	@plan.destroy
	    
	    respond_to do |format|
	      format.html { redirect_to budgets_path }
	    end
    end

	private
	def set_plan
		@plan = AllocationPlan.where(:user_id => current_user_id).find(params[:id])
	end

	def plan_params
    	params.required(:allocation_plan).permit(:name)
    end
 end
  