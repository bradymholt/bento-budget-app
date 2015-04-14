class TransactionType < ActiveRecord::Migration
  def change
  	add_column :transactions, :transaction_type, :string
  end
end
