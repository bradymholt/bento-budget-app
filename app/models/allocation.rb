class Allocation < ActiveRecord::Base
	before_validation :before_validation
	before_save :before_save
	validates :user_id, :date, :name, :presence => true
	validate :validate_allocations_total, :validate_source_transactions
	has_many :source_transactions, -> { where 'envelope_id IS NULL'}, :class_name => 'Transaction', :foreign_key => 'allocation_id', :autosave => true
	has_many :envelope_allocations, -> { where 'envelope_id IS NOT NULL'}, :class_name  => 'Transaction', :foreign_key => 'allocation_id', :autosave => true, :dependent => :destroy
	has_one :envelope_group, through: :envelope
	belongs_to :user
	before_destroy :handle_destroy

	def source_amount
		(source_transactions.collect{|t|t.amount}.reduce(:+) || 0.00).round(2)
	end

	def envelope_amounts=(amounts)
		amounts.reject!{ |a| a[:amount].to_d == 0 }
		envelope_allocations.each(&:mark_for_destruction)
		unallocated_income_envelope_id = Envelope.unallocated_income_envelope_id(self.user_id)
		amounts.each do |envelope_amount|
			name = (envelope_amount[:envelope_id] != unallocated_income_envelope_id.to_s) ? self.name : ('UNALLOCATED FROM ' + self.name)
			envelope_allocations.build({ 
				:user_id => self.user_id, 
				:name => name, 
				:date => self.date, 
				:envelope_id => envelope_amount[:envelope_id], 
				:amount => (source_amount < 0 ? (envelope_amount[:amount].to_d.abs * -1) : envelope_amount[:amount].to_d.abs) 
			})
		end
	end

	def envelope_amounts
		Hash[envelope_allocations.reject{ |a| a.marked_for_destruction?}.collect { |e| [e[:envelope_id], e[:amount]]}]
	end

	def all_envelope_ids
		ids = source_transactions.map { |t| t.envelope_id }
		ids << envelope_allocations.map { |t| t.envelope_id }
		ids.flatten
	end

	def self.new_with_defaults(source_transactions)
		allocation = Allocation.new
		allocation.source_transactions = source_transactions
		allocation.date = source_transactions.min_by { |s| s.date }.date
		name_prepend = ""
	
		if source_transactions.size == 1
			name_prepend = allocation.source_transactions[0].name + " "
		end
	
		if allocation.source_amount >= 0
			allocation.name = "--#{name_prepend}FUNDING--"
		else
			allocation.name = "--#{name_prepend}ALLOCATION--"
		end
		
		allocation
	end

	private
	def before_validation
		envelope_allocations.each do |e|
			e.user_id = self.user_id
			e.account_id = 0 #prevent validation errors, will be set to nil on in before_save
		end
	end

	def before_save
		source_transactions.each do |i|
			i.envelope_id = nil #signify allocation source
		end

		envelope_allocations.each do |e|
			e.account_id = nil #signify envelope allocation
		end
	end

	def validate_source_transactions
		if source_transactions.any? { |i| i.is_transfer? || i.is_split_parent? || i.is_split_child?}
			errors[:base] << "Allocation transactions must not already be transfer or split transactions."
		end
	end
	def validate_allocations_total
		allocated_total = (envelope_amounts.values.reduce(:+) || 0.00).abs
		source_total = source_amount.abs
		if allocated_total != source_total
			errors[:base] << "Total allocated amount of #{sprintf("%#.2f", allocated_total)} must equal source amount of #{sprintf("%#.2f", source_total)}."
		end
	end

	def handle_destroy
		unallocated_income_envelope_id = Envelope.unallocated_income_envelope(self.user_id)
		source_transactions.update_all(:envelope_id => unallocated_income_envelope_id, :allocation_id => nil)
	end
end