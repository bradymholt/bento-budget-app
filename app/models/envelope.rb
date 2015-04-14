class Envelope < ActiveRecord::Base
	attr_accessor :delete_move_to_envelope_id
	belongs_to :envelope_group
	belongs_to :user
	has_many :transactions
	has_many :allocation_plan_items, :dependent => :destroy
	has_many :budgets, :dependent => :destroy
	has_many :transaction_filters, :dependent => :destroy
	has_one :budget
	accepts_nested_attributes_for :budget, :allow_destroy => true
	validates :name, :user_id, :envelope_group_id, :presence => true
	before_destroy :handle_destroy
	default_scope -> { order('envelopes.sort_index, envelopes.name') }
	scope :with_balance, lambda { |user_id|
		 joins("LEFT OUTER JOIN transactions ON transactions.envelope_id = envelopes.id")
		 .select("envelopes.*, IFNULL(SUM(transactions.amount),0) as balance, COUNT(transactions.amount) as transaction_count")
		 .group("envelopes.id")
		 .where(:user_id => user_id)
	}
	scope :with_groups, lambda { |user_id|
		includes(:envelope_group)
		.preload(:envelope_group)	
        .where(:user_id => user_id)
        .where(envelope_groups: { visible: true })
        .order("envelope_groups.user_id, envelope_groups.sort_index, envelope_groups.name, envelopes.sort_index, envelopes.name")
	}

	def as_json(options={})
		super(:only=> [:id, :name, :balance, :transaction_count], :include => { :envelope_group => { :only => [:id, :name], :methods => [:is_global] } } )
	end

	def name_with_group
		result = ""
		if !self.envelope_group.is_global?
			result = self.envelope_group.name + " - "
		end
		result = result + self.name
	end

	def is_new_transactions_envelope?
		self.envelope_group_id == EnvelopeGroup::ENVELOPE_GROUPS[:new_transactions]
	end

	def is_unallocated_income_envelope?
		self.envelope_group_id == EnvelopeGroup::ENVELOPE_GROUPS[:unallocated_income]
	end

	def is_hidden_envelope?
		self.envelope_group_id == EnvelopeGroup::ENVELOPE_GROUPS[:hidden]
	end

	def self.new_transactions_envelope_id(user_id)
			Envelope
				.where(:user_id => user_id)
				.where(:envelope_group_id => EnvelopeGroup::ENVELOPE_GROUPS[:new_transactions])
				.pluck(:id).first
	end

	def self.unallocated_income_envelope_id(user_id)
			Envelope
				.where(:user_id => user_id)
				.where(:envelope_group_id => EnvelopeGroup::ENVELOPE_GROUPS[:unallocated_income])
				.pluck(:id).first
	end

	def self.unallocated_income_envelope(user_id)
		Envelope.where(:user_id => user_id).where(:envelope_group_id => EnvelopeGroup::ENVELOPE_GROUPS[:unallocated_income]).first
	end

	def self.hidden_envelope_id(user_id)
			Envelope
				.where(:user_id => user_id)
				.where(:envelope_group_id => EnvelopeGroup::ENVELOPE_GROUPS[:hidden])
				.pluck(:id).first
	end
	
	protected
	def handle_destroy
    	if !@delete_move_to_envelope_id.blank?
    		Transaction.update_all( { :envelope_id => @delete_move_to_envelope_id }, { :envelope_id => self.id} )
    		Transfer.update_all( { :from_envelope_id => @delete_move_to_envelope_id }, { :from_envelope_id => self.id} )
    		Transfer.update_all( { :to_envelope_id => @delete_move_to_envelope_id }, { :to_envelope_id => self.id} )
    	else 
    		if transactions.size > 0
	    		errors[:base] << "An envelope to move transactions to must be specified."
	    		return false 
	    	else
	    		return true
	    	end
    	end
  	end
end
