class AllocationPlanItemsController < ApplicationController
  respond_to :html, :json

   def index
    @items = AllocationPlanItem.where(:allocation_plan_id => params[:allocation_plan_id])
    respond_with(@items)
  end

   def update
        @allocation = AllocationPlanItem.find_or_initialize_by(allocation_plan_id: params[:allocation_plan_id], envelope_id: params[:envelope_id])
        @allocation.amount = params[:amount]
        if !@allocation.valid?
          @allocation.amount = 0
        end

        if @allocation.save
          respond_to do |format|
            format.json { render :json => {:amount => @allocation.amount} }
            format.html { redirect_to budgets_url }
          end
        else
           respond_with(@allocation, :status => :unprocessable_entity)
        end
    end
 end