class SubscriptionNotificationType < ActiveRecord::Migration
  def change
  	rename_column :subscription_notifications, :type, :transaction_type
  end
end
