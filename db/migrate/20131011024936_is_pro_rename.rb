class IsProRename < ActiveRecord::Migration
  def change
  	rename_column :users, :is_pro, :is_subscriber
  end
end
