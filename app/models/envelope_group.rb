class EnvelopeGroup < ActiveRecord::Base
	ENVELOPE_GROUPS = { :new_transactions => 1, :unallocated_income => 2, :hidden => 3 }
	attr_accessor :delete_move_to_group_id, :first_envelope_name
	has_many :envelopes
	belongs_to :user
	validates :name, :presence => true
	validates :first_envelope_name, :presence => true, :on => :create, :unless => lambda { self.user_id.blank? }
	after_create :create_first_envelope
	before_destroy :handle_destroy
	default_scope -> { order('envelope_groups.sort_index, envelope_groups.name') }
	scope :with_envelopes, lambda { |user_id| 
		includes(:envelopes)
		.where(envelopes: { user_id: user_id})
		.where(:visible => true)
		.order('envelope_groups.user_id, envelope_groups.sort_index, envelope_groups.name, envelopes.sort_index, envelopes.name')
	}

	def as_json(options={})
		super(:only=> [:id, :name])
	end

	def is_global?
		self.user_id.nil?
	end

	def is_global
		is_global?
	end

	protected
	def create_first_envelope
		first_envelope = Envelope.new
     	first_envelope.user_id = self.user_id
     	first_envelope.name = self.first_envelope_name
     	first_envelope.envelope_group_id = self.id
     	first_envelope.save
	end

	def handle_destroy
    	if !@delete_move_to_group_id.blank?
    		Envelope.update_all( { :envelope_group_id => @delete_move_to_group_id }, { :envelope_group_id => self.id} )
    	else 
    		if envelopes.size > 0
	    		errors[:base] << "An envelope to move transactions to must be specified."
	    		return false 
	    	else 
	    		return true
	    	end
    	end
  	end
end
