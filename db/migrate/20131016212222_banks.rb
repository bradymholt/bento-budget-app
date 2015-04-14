class Banks < ActiveRecord::Migration
  def change
  	create_table :auto_import_methods do |t|
      t.string :name
      t.timestamps
    end
    execute "INSERT INTO auto_import_methods (name) VALUES ('ofx')"
    execute "INSERT INTO auto_import_methods (name) VALUES ('scrape')"
    rename_column :banks, :ofx_fid, :fid
    add_column :banks, :auto_import_method_id, :integer, :default => 1
  end
end
