class AllocationPlanRatio < ActiveRecord::Migration
  def change
  	rename_column :allocation_plans, :budget_ratio, :monthly_occurance
  end
end
