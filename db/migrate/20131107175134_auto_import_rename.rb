class AutoImportRename < ActiveRecord::Migration
  def change
  	rename_column :accounts, :auto_import_account_number, :linked_account_number
    rename_column :accounts, :auto_import_bank_code, :linked_bank_code
    rename_column :accounts, :auto_import_user_id, :linked_user_id
    rename_column :accounts, :auto_import_password, :linked_password
    rename_column :accounts, :auto_import_last_success_date, :linked_last_success_date
    rename_column :accounts, :auto_import_last_balance, :linked_last_balance
    rename_column :accounts, :auto_import_last_balance_date, :linked_last_balance_date
    rename_column :accounts, :auto_import_last_attempt_error, :linked_last_attempt_error
    rename_column :accounts, :auto_import_last_error_message, :linked_last_error_message
    rename_column :accounts, :auto_import_initial_balance_bank_transaction_ids, :linked_initial_balance_bank_transaction_ids
    rename_column :accounts, :auto_import_security_answers, :linked_security_answers
    rename_column :accounts, :auto_import_last_error_message_detailed, :linked_last_error_message_detailed
    rename_column :accounts, :auto_import_last_attempt_error_bad_request, :linked_last_attempt_error_bad_request
  end
end
