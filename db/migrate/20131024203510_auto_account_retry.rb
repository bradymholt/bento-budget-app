class AutoAccountRetry < ActiveRecord::Migration
  def change
  	add_column :accounts, :auto_import_last_attempt_error_bad_request, :boolean
  end
end
