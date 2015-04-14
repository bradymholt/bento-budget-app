class BankNotes < ActiveRecord::Migration
  def change
  	add_column :banks, :notes, :string
  end
end
