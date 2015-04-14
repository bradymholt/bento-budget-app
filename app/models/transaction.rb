class Transaction < ActiveRecord::Base
	TYPES = { :debit => "DEBIT" , :deposit => "DEPOSIT" , :income => "INCOME" }
	attr_accessor :rolling_balance, :affected_envelope_ids, :is_split_parent, :is_split_child
	belongs_to :account 
	belongs_to :user
	belongs_to :envelope
	belongs_to :parent, :class_name  => 'Transaction', :foreign_key => "parent_transaction_id"
	has_many :splits, -> {where 'parent_transaction_id != id'}, :class_name  => 'Transaction', :foreign_key => "parent_transaction_id", :autosave => true, :dependent => :destroy
	has_one :envelope_group, through: :envelope
	validates :user_id, :name, :date, :presence => true
	validates :amount, :presence => true
	validate :validate_splits_total_match_amount, :validate_single_type, :validate_envelope_id, :validate_account_id
	default_scope -> { order('transactions.date DESC, transactions.id DESC') }
	before_save :handle_type_amount

	def as_json(options={})
		super(:only=> [:id, :name, :amount, :notes, :envelope_id], :methods => [:date_formatted, :is_associated] )
	end

	def date_formatted
		date.strftime("%m/%d/%Y")
	end

	def is_split_parent?
		is_split_parent || (!parent_transaction_id.nil? && parent_transaction_id == id)
	end

	def is_split_child?
		is_split_child || (!parent_transaction_id.nil? && parent_transaction_id != id)
	end

	def is_transfer?
		!transfer_id.nil?
	end

	def is_allocation?
		!allocation_id.nil?
	end

	def is_associated?
		is_split_parent? || is_split_child? || is_transfer? || is_allocation?
	end

	def is_associated
		is_associated?
	end

	def can_edit_amount?
		import_id.nil?
	end

	def envelope_amounts=(amounts)
		amounts.reject!{ |a| a[:amount].to_d == 0 && a[:envelope_id].blank?}
		if amounts.size > 0
			splits.each(&:mark_for_destruction)
			
			if amounts.length == 1	
				self.parent_transaction_id = nil #signify NO split!
				self.envelope_id = amounts[0][:envelope_id]
				self.notes = amounts[0][:notes]
				self.amount = self.amount #Do not set amount from amounts!
			else 	
				self.is_split_parent = true
				self.parent_transaction_id = id #signify split!
				self.envelope_id = nil #signify split!
				
				amounts.each do |split|
					if split[:envelope_id].blank? && split[:amount].to_d == 0
						next
					end

					splits.build({ 
						:is_split_child => true,
						:user_id => self.user_id, 
						:name => '--SPLIT-- ' + self.name, 
						:date => self.date, 
						:transaction_type => self.transaction_type,
						:envelope_id => split[:envelope_id], 
						:notes => split[:notes],
						:amount => (!self.amount.nil? && self.amount < 0) ? (split[:amount].to_d.abs * -1) : split[:amount].to_d.abs
					})
				end
			end
		end
	end

	def envelope_amounts
		source_transactions = []

		if !is_split_parent?
			source_transactions << self
		else
			source_transactions = splits.reject{ |s| s.marked_for_destruction?}
		end

		source_transactions.collect { |s| { :envelope_id => s[:envelope_id], :amount => (!s[:amount].nil? ? (s[:amount]).abs : nil), :notes => s[:notes] } }
	end

	def self.apply_rolling_balance(transactions, ending_balance)
		#Note: Order assumed to be .order('date DESC, id ASC') !
		transactions.each do |trans|
			trans.rolling_balance = ending_balance
			ending_balance -= trans.amount
		end

		return transactions
	end

	def self.new_with_defaults(user_id)
		trans = Transaction.new
		trans.user_id = user_id
		trans.date ||= Date.today
		trans.transaction_type = Transaction::TYPES[:debit]
		trans.envelope_id = Envelope.new_transactions_envelope_id(user_id)
  		trans
	end

	private
	def handle_type_amount
		if !self.transaction_type.blank?
			case self.transaction_type
		        when Transaction::TYPES[:debit] 
		        	self.amount = (self.amount.abs * -1)
		        when Transaction::TYPES[:deposit] 
		        	self.amount = (self.amount.abs)
		        when Transaction::TYPES[:income] 
		        	self.amount = (self.amount.abs)
		        	if !is_allocation?
		        		self.envelope_id = Envelope.unallocated_income_envelope_id(self.user_id)
		        	end
		    end
		end
	end

	def validate_envelope_id
		if !is_split_parent? && !is_allocation? && envelope_id.nil? 
			errors.add(:envelope_id, "is required.")
		elsif is_split_parent? && !envelope_id.nil?
			errors.add(:envelope_id, "must be empty if transaction has assignments.")
		end
	end

	def validate_account_id
		if !is_split_child? && !is_transfer? && !is_allocation? && account_id.nil? 
			errors.add(:account_id, "is required.")
		end
	end

	def validate_single_type
		error = false
		if self.is_allocation? && (self.is_transfer? || self.is_split_child? || self.is_split_parent?)
			error = true
		elsif self.is_transfer? && (self.is_allocation? || self.is_split_child? || self.is_split_parent?)
			error = true
		elsif (self.is_split_child? || self.is_split_parent?) && (self.is_transfer? || self.is_allocation?)
			error = true
		end

		if error
			errors[:base] << "Transaction can only be of one type: allocation, transfer, or split."
		end
	end

	def validate_splits_total_match_amount
		if is_split_parent? && (envelope_amounts.collect{|a| a[:amount].abs}.reduce(:+) != self.amount.abs)
			errors[:base] << "Total allocated amount does not match transaction amount."
		end
	end
end
