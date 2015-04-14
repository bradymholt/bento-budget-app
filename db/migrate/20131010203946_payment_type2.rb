class PaymentType2 < ActiveRecord::Migration
  def change
  	remove_column :payment_notifications, :status
  end
end
