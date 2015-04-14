require 'open-uri'

namespace :db do
	desc "Reset and fill database with initial user"
	task :dev => [:reset] do

		#Admin User
		user = User.create! :name => 'Brady Test', :email => 'brady.holt@gmail.com', :password => '123456', :password_confirmation => '123456', :is_subscriber => true
		puts "User ID: " + user.id.to_s

		boaBank = Bank.where(:ofx_fid => '6812').first
		boaAccount = user.accounts.create! :name => 'Bank Of America', :initial_balance => 1000, :initial_balance_date => DateTime.now - 1.year, :bank => boaBank, :account_type => 'CHECKING', :active => true
		boaAccount.linked_account_number = "004778226280"
		boaAccount.linked_bank_code = "111000025"
		boaAccount.linked_user_id = "brady.holt"
		boaAccount.linked_password = "9796BmH9796"
		boaAccount.linked_security_answers = "brad"
		boaAccount.linked_last_success_date = DateTime.now - 1.week
		boaAccount.save

		userUnallocatedIncomeEnvelope = Envelope.where(:user_id => user.id).where(:envelope_group_id => EnvelopeGroup::ENVELOPE_GROUPS[:unallocated_income]).first
		initialBalance = userUnallocatedIncomeEnvelope.transactions.create! :user => user, :account_id => boaAccount.id, :name => 'INITIAL BALANCE', :amount => 4000.01, :date => (DateTime.now - 3.weeks)
		userUnallocatedIncomeEnvelope.transactions.create! :user => user, :account_id => boaAccount.id, :name => 'PAYCHEX ACH PAYROLL', :amount => 1100.01, :date => (DateTime.now - 2.weeks)
		userUnallocatedIncomeEnvelope.transactions.create! :user => user, :account_id => boaAccount.id, :name => 'PAYCHEX ACH PAYROLL', :amount => 1100.01, :date => (DateTime.now - 1.day)

		boaAccount.initial_transaction_id = initialBalance.id
		boaAccount.save
		
		userNewEnvelope = Envelope.where(:user_id => user.id).where(:envelope_group_id => EnvelopeGroup::ENVELOPE_GROUPS[:new_transactions]).first
		userNewEnvelope.transactions.create! :user => user, :account_id => boaAccount.id, :name => 'SUBWAY', :amount => -11.42, :date => (DateTime.now - 1.day)
		userNewEnvelope.transactions.create! :user => user, :account_id => boaAccount.id, :name => 'TARGET', :amount => -60.29, :date => (DateTime.now - 1.day)
		userNewEnvelope.transactions.create! :user => user, :account_id => boaAccount.id, :name => 'WALMART', :amount => 10.29, :date => (DateTime.now - 1.day)

		eatingOutEnvelope = Envelope.where(:user_id => user.id, :name => 'Eating Out').first
		eatingOutEnvelope.transactions.create! :user => user, :account_id => boaAccount.id, :name => 'LUPE TORTILLA', :amount => -29.38, :date => (DateTime.now - 1.week)
		eatingOutEnvelope.transactions.create! :user => user, :account_id => boaAccount.id, :name => 'MISSION BURITTO', :amount => -59.24, :date => (DateTime.now - 1.month)
		
		gasEnvelope = Envelope.where(:user_id => user.id, :name => 'Gas').first
		gasEnvelope.transactions.create! :user => user, :account_id => boaAccount.id, :name => 'SHELL OIL', :amount => -38.38, :date => (DateTime.now - 1.month)
		
		mortgateEnvelope = Envelope.where(:user_id => user.id, :name => 'Mortgage').first
		mortgateEnvelope.transactions.create! :user => user, :account_id => boaAccount.id, :name => 'BOA MORTGAGE', :amount => -838.28, :date => (DateTime.now - 2.weeks)

		# monthlyFunding = user.allocation_plans.create! :name => 'Mid Month Funding'
		# monthlyFunding.allocation_plan_items.create! :envelope_id => eatingOutEnvelope.id, :amount => 20.00
		# monthlyFunding.allocation_plan_items.create! :envelope_id => gasEnvelope.id, :amount => 30.00
		# monthlyFunding.allocation_plan_items.create! :envelope_id => mortgateEnvelope.id, :amount => 40.00

		# monthlyFunding = user.allocation_plans.create! :name => 'End Month Funding'
		# monthlyFunding.allocation_plan_items.create! :envelope_id => eatingOutEnvelope.id, :amount => 0.00
		# monthlyFunding.allocation_plan_items.create! :envelope_id => gasEnvelope.id, :amount => 25.00
		# monthlyFunding.allocation_plan_items.create! :envelope_id => mortgateEnvelope.id, :amount => 10.00

		user.transaction_filters.create! :search_text => 'CHEVRON', :amount => '11.00', :envelope_id => gasEnvelope.id
		user.transaction_filters.create! :search_text => 'PAYROLL', :envelope_id => userUnallocatedIncomeEnvelope.id

		# user.budgets.create! :envelope_id => eatingOutEnvelope.id, :amount => 10.00
		# user.budgets.create! :envelope_id => mortgateEnvelope.id, :amount => 500.00
	end

	desc "Import banks from OFX Home"
	task :bank_import => [:environment] do
		doc_all_institutions = Nokogiri::XML(open("http://www.ofxhome.com/api.php?all=yes"))
		institution_ids = doc_all_institutions.xpath("/institutionlist/institutionid//@id").map {|c| c.content }
		institution_ids.each do |id|
			doc_institution = Nokogiri::XML(open("http://www.ofxhome.com/api.php?lookup=#{id}"))
			name = doc_institution.xpath("//institution/name")[0].content
			fid = doc_institution.xpath("//institution/fid")[0].content
			org = doc_institution.xpath("//institution/org")[0].content
			url = doc_institution.xpath("//institution/url")[0].content
			ofxfail = doc_institution.xpath("//institution/ofxfail")[0].content
			sslfail = doc_institution.xpath("//institution/sslfail")[0].content

			if ofxfail == "0" #&& sslfail == "0")
				bank = Bank.find_or_initialize_by(import_id: id)
				bank.name = name
				bank.ofx_fid = fid
				bank.ofx_org = org
				bank.ofx_uri = url

				if bank.new_record?
					bank.active = (ofxfail == "0")
					bank.auto_import_method_id = AutoImportMethod::IMPORT_METHODS[:ofx]
				elsif bank.active && (ofxfail != "0")
					bank.active = false
				end

				bank.save
			end
		end
	end
end