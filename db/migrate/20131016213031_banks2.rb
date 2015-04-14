class Banks2 < ActiveRecord::Migration
  def change
  	rename_column :banks, :fid, :ofx_fid
  end
end
