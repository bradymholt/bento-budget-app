class AllocationPlanSortIndex < ActiveRecord::Migration
  def change
  	add_column :allocation_plans, :sort_index, :integer
  end
end
