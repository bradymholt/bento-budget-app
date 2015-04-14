class AccountSecurityAnswer < ActiveRecord::Migration
  def change
  	add_column :accounts, :auto_import_security_answers, :string
  end
end
