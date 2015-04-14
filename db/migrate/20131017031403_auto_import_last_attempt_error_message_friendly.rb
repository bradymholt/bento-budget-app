class AutoImportLastAttemptErrorMessageFriendly < ActiveRecord::Migration
  def change
  	rename_column :accounts, :auto_import_last_attempt_error_message, :auto_import_last_error_message
  	add_column :accounts, :auto_import_last_error_message_detailed, :string
  end
end
