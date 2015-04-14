class AllocationPlanItem < ActiveRecord::Base
	belongs_to :allocation_plan
	belongs_to :envelope
	has_one :user, :through => :allocation_plan 
	has_one :envelope_group, :through => :envelope
	validates :envelope_id, :presence => true
	validates :amount, :numericality => true, :presence => true
	before_save :ensure_amount_positive

	def as_json(options={})
		super(:only=> [:envelope_id, :amount])
	end

	private
	def ensure_amount_positive
		self.amount = self.amount.abs
	end
end
