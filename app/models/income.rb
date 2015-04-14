class Income < ActiveRecord::Base
	validates :name, :presence => true
	validates :amount, :numericality => { :other_than => 0.0 }, :presence => true
	validates :income_frequency_id, :presence => true
	validate :validate_allocation_method_id
	belongs_to :income_frequency
	belongs_to :allocation_method
	has_many :allocation_plans, :dependent => :destroy
	has_many :grouped_incomes, :class_name  => 'Income', :foreign_key => "allocation_method_grouped_with_income_id", :dependent => :nullify
	after_create :handle_create
	after_update :handle_update
	after_destroy :handle_destroy

	def income_monthly
		(amount * income_frequency.monthly_occurance)
	end

	def allocated_monthly
		total = (amount * (income_frequency.monthly_occurance.floor / allocation_method.monthly_occurance.floor) * allocation_method.monthly_occurance)
	end	

	def setup_allocation_plans
		if !self.allocation_method_grouped_with_income_id.nil?
			AllocationPlan.destroy_all(:income_id => self.id)
		else
			incomes = [self]
			grouped_incomes.reload
			
			if (grouped_incomes.count > 0)
				incomes = (incomes + grouped_incomes.target)
			end

			plan_name_prefix = incomes.collect{ |g| g.name }.join(', ')

			if allocation_method.monthly_occurance == 1
				current_plan_amount = incomes.collect{ |i| i.allocated_monthly }.reduce(:+)
				
				plans = gather_allocation_plans(1)
				target_plan = plans.first
				target_plan.name = (plan_name_prefix + " - Monthly")
				target_plan.amount = current_plan_amount
				target_plan.monthly_occurance = 1
				target_plan.sort_index = 1
				target_plan.save
			else
				plans = gather_allocation_plans(allocation_method.monthly_occurance.ceil)

				#full allocations
				for c in 1..allocation_method.monthly_occurance.to_i
					current_plan_amount =  (incomes.collect{ |i| i.amount }.reduce(:+)) * (income_frequency.monthly_occurance.floor.to_f / allocation_method.monthly_occurance.floor.to_f)
					
					target_plan = plans[c - 1]
					target_plan.name = (plan_name_prefix + " - #{c.ordinalize} Check")
					target_plan.amount = current_plan_amount
					target_plan.monthly_occurance = 1
					target_plan.sort_index = c
					target_plan.save
				end

				#partial allocations
				if (allocation_method.monthly_occurance % 1) > 0
					income_occurance = income_frequency.monthly_occurance.to_i + 1
					current_plan_amount = incomes.collect{ |i| i.amount }.reduce(:+)

					target_plan = plans[income_occurance - 1]
					target_plan.name = (plan_name_prefix + " - #{income_occurance.ordinalize} Check")
					target_plan.amount = current_plan_amount
					target_plan.monthly_occurance = (income_frequency.monthly_occurance % 1)
					target_plan.sort_index = income_occurance
					target_plan.save
				end
			end
		end
	end	

	def gather_allocation_plans(needed_count)
		current_plans = AllocationPlan.where(:income_id => self.id).to_ary
		if current_plans.size > needed_count
			for i in (needed_count + 1)..current_plans.size
				current_plans[i - 1].destroy #remove additional plans
			end
		elsif current_plans.size < needed_count
			for i in 1..(needed_count - current_plans.size)
				current_plans << AllocationPlan.new({:user_id => self.user_id, :income_id => self.id})
			end
		end

		current_plans.take(needed_count)
	end

	protected
	def handle_create
		setup_allocation_plans
		if !self.allocation_method_grouped_with_income_id.nil?
			#setup_allocation_plans on new group parent
			Income.find(allocation_method_grouped_with_income_id).setup_allocation_plans
		end
	end

	def handle_update
		if self.allocation_method_id_changed?
			#allocation method changed so remove any incomes grouped with this one
			Income.update_all( { :allocation_method_grouped_with_income_id => nil }, { :allocation_method_grouped_with_income_id => self.id } )
		end

		setup_allocation_plans

		Income.where.not(id: self.id).each do |i|
			i.setup_allocation_plans
		end
	end

	def handle_destroy
		Income.where.not(id: self.id).each do |i|
			i.setup_allocation_plans
		end
	end

	def validate_allocation_method_id
		if !income_frequency_id.nil? && allocation_method_id.blank?
			errors[:base] << "You must specify how you would like to allocate this income."
		end
	end
end
