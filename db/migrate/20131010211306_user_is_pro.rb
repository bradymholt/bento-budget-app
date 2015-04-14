class UserIsPro < ActiveRecord::Migration
  def change
  	change_column :users, :is_pro, :boolean, :default => false
  end
end
