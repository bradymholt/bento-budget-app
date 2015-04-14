namespace :bot do
	task :all => [:auto_import_transactions, :send_new_transactions_notifications]

	task :auto_import_transactions => [:environment] do
		puts "[bot:auto_import_transactions] - START"
		
		#update only linked accounts with saved password b/c this is unattended update
		linked_accounts = Account.where_linked.reject { |a| a.linked_password.blank? } 
		linked_accounts.each do |acct|
			print " [account.id=#{acct.id}] - "
			begin
				accepted_count = acct.linked_import_transactions(acct.linked_password)
				puts "Recorded #{accepted_count} transaction(s)."
			rescue Exception => e
				puts e.message
				Rails.logger.debug e
			end
		end

		puts "[bot:auto_import_transactions] - END"
	end

	task :send_new_transactions_notifications => [:environment] do
		puts "[bot:send_new_transactions_notifications] - START"

		user_ids_to_notify = Transaction
			.joins(:envelope).joins(:user)
			.where(envelopes: { envelope_group_id: EnvelopeGroup::ENVELOPE_GROUPS[:new_transactions] })
			.group('transactions.user_id')
			.having('count(*) >= users.new_transaction_count_notify')
			.select('transactions.user_id, users.new_transaction_count_notify')
			.map{|u| u.user_id}

		users = User.find(user_ids_to_notify)
		users.each do |u|
			transactions = Transaction
				.joins(:envelope)
				.where(:user_id => u.id)
				.where(envelopes: { envelope_group_id: EnvelopeGroup::ENVELOPE_GROUPS[:new_transactions] })

			puts  " [user.id=#{u.id},email=#{u.email},transaction_count=#{transactions.size}] - Sending email."
			UserMailer.new_transactions(u, transactions).deliver
		end

		puts "[bot:send_new_transactions_notifications] - END"
	end
end