class Account < ActiveRecord::Base
	LINKED_PASSWORD_MASK = "*****"
	LINKED_MAX_FREQ_HOURS = 6
	belongs_to :bank
	belongs_to :user
	attr_accessor :initial_balance_date, :initial_balance_amount
	has_many :transactions, :dependent => :destroy
	validates :name, :user_id, :account_type, :presence => true
	validates_presence_of :initial_balance_date, :initial_balance_amount, :on => :create
	validates_numericality_of :initial_balance_amount, :on => :create 
	before_save :create_initial_transaction #keep before 'belongs_to :initial_transaction'; http://pivotallabs.com/activerecord-callbacks-autosave-before-this-and-that-etc/
	belongs_to :initial_transaction, :class_name => "Transaction", :foreign_key => "initial_transaction_id", :autosave => true
	before_create :scrub_amount, :set_initial_linked_values
	after_create :set_initial_transaction_account
	before_destroy :destroy_allocations, prepend: true
	default_scope -> { order('accounts.name') }
	scope :with_balance, lambda { |user_id|
		 joins("LEFT OUTER JOIN transactions ON transactions.account_id = accounts.id")
		 .select("accounts.*, IFNULL(SUM(transactions.amount),0) as balance")
		 .group("accounts.id")
		 .where(:user_id => user_id)
	}

	def linked_password_new
		if self.linked_password.blank?
			""
		else
			Account::LINKED_PASSWORD_MASK
		end
	end

	def linked_password_new=(new_password)
		if new_password.blank?
			self.linked_password = nil
		elsif (new_password != Account::LINKED_PASSWORD_MASK)
			self.linked_password = new_password
		end
	end

	def as_json(options={})
		super(:only=> [:id, :name, :balance])
	end

	def import_transactions(transactions, date_start)
		accepted_transaction_count = 0
		existing_transactions = Transaction.where(:account_id => self.id).where('date >= ?', date_start)
    	new_transactions_envelope_id =  Envelope.new_transactions_envelope_id(self.user_id)
    
	    transactions.each do |t|
	       exists_by_import_id = existing_transactions.any? { |existing| existing.import_id == t[:id] }
	       is_initial_balance_transaction = !self.linked_initial_balance_bank_transaction_ids.nil? && self.linked_initial_balance_bank_transaction_ids.include?(t[:id])
	          
	       if !exists_by_import_id && !is_initial_balance_transaction && (t[:date].to_date >= self.initial_transaction.date)
				new_trans = Transaction.new
				new_trans.account_id = self.id
				new_trans.user_id = self.user_id
				new_trans.envelope_id = new_transactions_envelope_id
				new_trans.import_id = t[:id] 
				new_trans.date = t[:date]
				new_trans.name = t[:name]
				new_trans.amount = t[:amount]
				
				if new_trans.amount >= 0
					new_trans.transaction_type = Transaction::TYPES[:deposit]
				else
					new_trans.transaction_type = Transaction::TYPES[:debit] 
				end 

				begin
					new_trans.save
					accepted_transaction_count = accepted_transaction_count + 1
				rescue Exception => e
					Rails.logger.info e.message
				end
	        end
	    end

	    return accepted_transaction_count
	end

	def linked?
		!bank_id.nil? && !linked_user_id.blank?
	end

	def self.where_linked
		Account.where(:active => true).where("bank_id IS NOT NULL AND linked_user_id IS NOT NULL and linked_user_id != ''")
	end

	def linked_frequency_allowed?
		if self.linked_last_success_date.nil?
			return true
		else 
			return (((DateTime.now.to_time - self.linked_last_success_date.to_time) / 1.hour).to_i >= Account::LINKED_MAX_FREQ_HOURS)
		end
	end

	def linked_import_transactions(linked_password)
		date_start = DateTime.now - 1.month
		accepted_transaction_count = 0

		
		if linked_frequency_allowed?
			begin
				raise ArgumentError, "Username not set." unless !self.linked_user_id.blank?
				raise ArgumentError, "Password not provided." unless !linked_password.blank?

				if linked_frequency_allowed?
					open_bank_proxy = OpenBankProxy.new_with_bank(self.bank)
					open_bank_proxy.user_id = self.linked_user_id
					open_bank_proxy.password = self.linked_password
					open_bank_proxy.security_answers = self.linked_security_answers

					logger.info "Fetching transactions for account id: #{id} via OpenBank."
				
					open_bank_response = open_bank_proxy.fetch_statement(self.linked_bank_code, self.linked_account_number, self.account_type, date_start)
					if !open_bank_response.is_error?
						statement = open_bank_response.statement
						if !statement.nil?
							accepted_transaction_count = import_transactions(statement[:transactions], date_start)
							if accepted_transaction_count > 0
								if !statement[:ledger_balance].nil?
									self.linked_last_balance = statement[:ledger_balance][:amount]
									self.linked_last_balance_date = statement[:ledger_balance][:date]
								end

				                TransactionFilter.run_filters(self.user_id)
			            	end
						end

						self.linked_last_success_date = DateTime.now
			           	self.linked_last_attempt_error = false
			           	self.linked_last_attempt_error_bad_request = false
				        self.linked_last_error_message = ''
				        self.linked_last_error_message_detailed = ''
				        self.linked_security_answers = ''  #clear or else they might be used at next prompt and be invalid
					else
						self.linked_last_attempt_error = true
						self.linked_last_attempt_error_bad_request = open_bank_response.is_bad_request?
		            	self.linked_last_error_message = open_bank_response.friendly_error
		            	self.linked_last_error_message_detailed = open_bank_response.detailed_error
		            end
		        end
			rescue Exception => e
				self.linked_last_attempt_error = true
				#bad request resuts from 4xx http status code and means we should not retry until we get updated info
				self.linked_last_attempt_error_bad_request = open_bank_response.is_bad_request?
	            self.linked_last_error_message = e.message
	            throw
			ensure 
				 self.save
			end
		end

		accepted_transaction_count
	end

	def inactivate
		allocate_trans = nil
		acct_trans_amount_total = Transaction.where(:account_id => self.id).sum(:amount)
		
		unallocated_income_envelope_id = Envelope.unallocated_income_envelope_id(self.user_id)
		offset_trans = Transaction.new
		offset_trans.account_id = self.id
		offset_trans.user_id = self.user_id
		offset_trans.name = 'REMOVED ACCOUNT - ' + self.name
		offset_trans.notes = "Offsetting transaction for account removal."
		offset_trans.date = Time.now

		if self.account_type != AccountType::ACCOUNT_TYPES[:credit_card]
			offset_trans.envelope_id = unallocated_income_envelope_id
			offset_trans.amount = (acct_trans_amount_total * -1)
		else
			hidden_envelope_id = Envelope.hidden_envelope_id(self.user_id)
			
			offset_trans.envelope_id = unallocated_income_envelope_id
			offset_trans.amount = ((acct_trans_amount_total - initial_transaction.amount)  * -1)
			
			initial_balance_credit_card_transaction = Transaction.new
			initial_balance_credit_card_transaction.envelope_id = hidden_envelope_id
			initial_balance_credit_card_transaction.account_id = self.id
			initial_balance_credit_card_transaction.user_id = self.user_id
			initial_balance_credit_card_transaction.name = 'REMOVED ACCOUNT - ' + self.name
			initial_balance_credit_card_transaction.notes = "Offsetting transaction for account removal."
			initial_balance_credit_card_transaction.date = Time.now
			initial_balance_credit_card_transaction.amount = (initial_transaction.amount * -1)

			if (initial_balance_credit_card_transaction.amount != 0)
				initial_balance_credit_card_transaction.save
			end
		end

		if offset_trans.amount != 0
			offset_trans.save
			allocate_trans = offset_trans
		end

		self.name += " (Inactive)"
		self.active = false
		self.save

		return allocate_trans

	end

	protected
	def scrub_amount
		if self.account_type == AccountType::ACCOUNT_TYPES[:credit_card]
			#force negative
			self.initial_balance_amount = (self.initial_balance_amount.to_f.abs * -1)
		else
			#force positive
			self.initial_balance_amount = self.initial_balance_amount.to_f.abs
		end
	end

	def create_initial_transaction
		if new_record?
			#create initial account transaction
			initial_balance_envelope_id = nil
			initial_type = nil

			if self.account_type == AccountType::ACCOUNT_TYPES[:credit_card] || self.initial_balance_amount.to_f == 0
				#initial balance will not be visible
				initial_balance_envelope_id = Envelope.hidden_envelope_id(self.user_id)
				initial_type = Transaction::TYPES[:debit]
			else
				initial_balance_envelope_id = Envelope.unallocated_income_envelope_id(self.user_id)
				initial_type = Transaction::TYPES[:deposit] 
			end

			build_initial_transaction({
				:user_id => self.user_id,
				:envelope_id => initial_balance_envelope_id,
				:name => 'NEW ACCOUNT - ' + self.name,
				:transaction_type => initial_type,
				:amount => self.initial_balance_amount,
				:notes => "Initial balance for new account.",
				:date => self.initial_balance_date }
			)
		end
	end

	def set_initial_transaction_account
		self.initial_transaction.account_id = self.id
		self.initial_transaction.save
	end

	def set_initial_linked_values
		if linked?
			self.linked_last_success_date = DateTime.now
			self.linked_last_balance = self.initial_balance_amount
			self.linked_last_balance_date = self.initial_balance_date
		end
	end

	protected
	def destroy_allocations
		allocation_ids = Transaction.where(:account_id => self.id).where('allocation_id IS NOT NULL').pluck(:allocation_id)
		Transaction.destroy_all(["allocation_id IN (?)",  allocation_ids])
		Allocation.where(:id => allocation_ids).destroy_all
  	end
end
