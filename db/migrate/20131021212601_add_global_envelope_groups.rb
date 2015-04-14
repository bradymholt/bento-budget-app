class AddGlobalEnvelopeGroups < ActiveRecord::Migration
  def change
  	add_column :envelope_groups, :visible, :boolean, :default => true
  	EnvelopeGroup.create! :name => 'Credit Card Initial Balances', :visible => false
  end
end
