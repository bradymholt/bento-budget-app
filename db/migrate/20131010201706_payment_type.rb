class PaymentType < ActiveRecord::Migration
  def change
  	add_column :payment_notifications, :type, :string
  end
end
