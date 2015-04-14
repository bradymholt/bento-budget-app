class PaymentNotificationsName < ActiveRecord::Migration
  def change
  	rename_table :payment_notifications, :subscription_notifications
  end
end
