
class TransactionFilter < ActiveRecord::Base
	attr_accessor :delete_after_save, :is_template
	belongs_to :user
	belongs_to :envelope
	has_many :transaction_filters
	validates :search_text, :envelope_id, :user_id, :presence => true
	after_save :handle_delete_after_save
	default_scope -> { order('search_text') }

	def self.run_filters(user_id)
		affected_envelope_ids = []
		new_transactions_envelope_id = Envelope
			.where(:user_id => user_id)
			.where(:envelope_group_id => EnvelopeGroup::ENVELOPE_GROUPS[:new_transactions])
			.pluck(:id)
		new_transactions = Transaction.where(:user_id => user_id, :envelope_id => new_transactions_envelope_id)
		filters = TransactionFilter.where(:user_id => user_id)
		
		new_transactions.each do |trans|
			matched_filter = filters.find { |f| trans.name.include?(f.search_text) && (f.amount.blank? || f.amount.abs == trans.amount.abs) }
			if !matched_filter.nil?
				affected_envelope_ids << matched_filter.envelope_id
				trans.envelope_id = matched_filter.envelope_id
				trans.notes = "Auto-assigned by filter"
				trans.save
			end
		end

		if affected_envelope_ids.size > 0
			affected_envelope_ids << new_transactions_envelope_id
		end

		affected_envelope_ids
	end
	
	protected
	def handle_delete_after_save
    	if @delete_after_save == 'true'
    		self.destroy
    	end
  	end
end
