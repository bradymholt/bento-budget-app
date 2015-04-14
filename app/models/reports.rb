 class Reports
	def self.envelope_spending(user_id, envelope_id, months_back)
		date_from = Date.today.beginning_of_month - months_back.months
		date_to = months_back == 0 ? Date.today : Date.today.beginning_of_month
		transactions = Transaction
			.where(:envelope_id => envelope_id)
			.where("transfer_id IS NULL AND allocation_id IS NULL")
			.where("date >= ?", date_from)
			.where("date < ?", date_to)
			.select(:date, :amount)
		grouped_by_month = transactions.group_by { |t| (t.date.utc.at_beginning_of_month.to_i * 1000) } #use UTC milliseconds for easy conversion to JavaScript date
		summed = grouped_by_month.collect{ |k, v| {:month => k, :sum => (v.collect{ |v| v.amount }.sum) * -1 } }
	end

	def self.envelope_group_spending(user_id, months_back)
		date_from = Date.today.beginning_of_month - months_back.months
		date_to = months_back == 0 ? Date.today : Date.today.beginning_of_month
		Transaction
			.select('envelope_groups.name, sum(transactions.amount) as amount, envelope_id, date, parent_transaction_id, transfer_id, allocation_id')
			.where(:user_id => user_id)
			.joins(:envelope_group).preload(:envelope_group)	
			.where(envelope_groups: { user_id: user_id} )
			.where("transfer_id IS NULL AND allocation_id IS NULL")
			.where("date >= ?", date_from)
			.where("date < ?", date_to)
			.group('envelope_groups.id')	
	end

	def self.funding_spending(user_id, month)
		transactions = Transaction.where(:user_id => user_id)
			.where("transfer_id IS NULL AND envelope_id IS NOT NULL")
			.where('date >= ? AND date < ?', month, month.to_date + 1.month)

		envelopes = Envelope
			.joins(:envelope_group).preload(:envelope_group)
			.where(:user_id => user_id)
			.where(envelope_groups: { user_id: user_id })
			.order("envelope_groups.user_id, envelope_groups.sort_index, envelope_groups.name, envelopes.sort_index, envelopes.name")
		
		data = envelopes.collect{ |e| {
				:envelope_group_name => e.envelope_group.name,
				:envelope_name => e.name, 
				:funded => (transactions.select{ |t| t.envelope_id == e.id }).inject(0){ |sum, t| sum  + (t.is_allocation? ? t.amount : 0) },
				:spent => (transactions.select{ |t| t.envelope_id == e.id }).inject(0){ |sum, t| sum  + (!t.is_allocation? ? t.amount : 0) },
				:diff => 0
			}
		}

		data.each{ |e| 
			e[:diff] = (e[:funded] - (e[:spent] * -1))
		}

		return data
	end

	def self.recurring_transactions(user_id, months_back)
		date_from = Date.today.beginning_of_month - months_back.months
		date_to = months_back == 0 ? Date.today : Date.today.beginning_of_month
		transactions = Transaction.where(:user_id => user_id)
						.where("date >= ?", date_from)
						.where("date < ?", date_to)
						.joins(:account)
						.group('transactions.name, accounts.name')
						.having('count(*) > 1')
						.order('count(*) DESC')
						.select('transactions.name, accounts.name as account_name, count(*) recurrance_count, max(transactions.date) last_recurrance_date')

	end
end

