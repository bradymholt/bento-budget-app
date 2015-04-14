class AccountInitialRemove < ActiveRecord::Migration
  def change
  	remove_column :accounts, :initial_balance_date
  end
end
