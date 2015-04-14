class BankPopular < ActiveRecord::Migration
  def change
  	add_column :banks, :featured, :boolean, default: false, :null => false, , :limit => 1000
  end
end
