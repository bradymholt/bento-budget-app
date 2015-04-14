class CreatePaymentNotifications < ActiveRecord::Migration
  def change
    create_table :payment_notifications do |t|
      t.text :params
      t.string :status
      t.string :transaction_id
      t.integer :user_id

      t.timestamps
    end

    add_column :users, :is_pro, :boolean
  end
end
