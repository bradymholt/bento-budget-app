class InitialBalance < ActiveRecord::Migration
  def change
  	remove_column :accounts, :initial_balance
  end
end
