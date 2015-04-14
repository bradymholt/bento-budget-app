class TrialPeriodRecord < ActiveRecord::Migration
  def change
  	add_column :users,  :is_trial_period_used, :boolean, :default => false
  end
end
