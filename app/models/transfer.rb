class Transfer < ActiveRecord::Base
	has_many :transactions
	belongs_to :from_envelope, :class_name  => 'Envelope', :foreign_key => "from_envelope_id"
	belongs_to :to_envelope, :class_name  => 'Envelope', :foreign_key => "to_envelope_id"
	validates :from_envelope_id, :to_envelope_id, :amount, :user_id, :date, :presence => true
	validates :amount, :numericality => true
	after_save :create_transactions
	before_destroy :remove_transactions

	def self.new_with_defaults
		transfer = Transfer.new
		transfer.date = Date.today
		transfer
	end

  	private
	def create_transactions
		if !id_changed?
			Transaction.destroy_all(:transfer_id => self.id) #this is update, delete existing transactions
		end

		fromEnvelope = Envelope.find(self.from_envelope_id)
		toEnvelope = Envelope.find(self.to_envelope_id)
		amt = self.amount.to_d

		if (amt != 0)
			#from transaction 
			fromTrans = Transaction.new
			fromTrans.user_id = self.user_id
			fromTrans.envelope_id = fromEnvelope.id
			fromTrans.transfer_id = self.id
			fromTrans.name = 'TRANSFER TO ' + toEnvelope.name
			fromTrans.amount = (amt.abs * -1)
			fromTrans.notes = self.notes
			fromTrans.date = self.date
			fromTrans.save

			#to transaction
			toTrans = Transaction.new
			toTrans.user_id = self.user_id
			toTrans.envelope_id = toEnvelope.id
			toTrans.transfer_id = self.id
			toTrans.name = 'TRANSFER FROM ' + fromEnvelope.name
			toTrans.amount = amt.abs
			toTrans.notes = self.notes
			toTrans.date = self.date
			toTrans.save
		end
	end

	def remove_transactions
		Transaction.destroy_all(:transfer_id => self.id)
	end
end
