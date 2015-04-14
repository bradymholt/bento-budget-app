class AllocationPlan < ActiveRecord::Base
	has_many :allocation_plan_items, :autosave => true, :dependent => :destroy
	belongs_to :user
	validates :name, :user_id, :presence => true
	default_scope -> { order('income_id ASC, sort_index ASC') }

	def allocations_by_envelope
		by_envelope = Hash[allocation_plan_items.collect { |a| [a.envelope_id, a.amount]}]
		by_envelope.default = 0.00
		by_envelope
	end

	def is_monthly_occurance_partial?
		(monthly_occurance % 1 > 0)
	end

	def monthly_occurance_partial_rational
		Rational(monthly_occurance % 1).rationalize(Rational('0.01'))
	end

	def monthly_occurance_partial_months
		((monthly_occurance % 1) * 12).ceil
	end

	def as_json(options={})
		super(:only=> [:id, :name])
	end
end

