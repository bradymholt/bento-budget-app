class Budget < ActiveRecord::Base
	validates :amount, numericality: true
	belongs_to :envelope
	belongs_to :user	
	before_save :ensure_amount_positive

	def as_json(options={})
		super(:only=> [:envelope_id, :amount])
	end
	
	private
	def ensure_amount_positive
		self.amount = self.amount.abs
	end
end
