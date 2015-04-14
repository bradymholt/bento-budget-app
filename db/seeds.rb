# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

EnvelopeGroup.create! :name => 'New Transactions', :sort_index => 0
EnvelopeGroup.create! :name => 'Unallocated Income', :sort_index => 1
EnvelopeGroup.create! :name => 'Hidden', :visible => false

AccountType.create! :name => "Checking", :value => "CHECKING"
AccountType.create! :name => "Savings", :value => "SAVINGS"
AccountType.create! :name => "Money Market", :value => "MONEYMRKT"
AccountType.create! :name => "Credit Card", :value => "CREDITCARD"

IncomeFrequency.create! :name => "Twice a Month", :monthly_occurance => 2
IncomeFrequency.create! :name => "Every Two Weeks", :monthly_occurance => 2.166
IncomeFrequency.create! :name => "Once a Month", :monthly_occurance => 1
IncomeFrequency.create! :name => "Once a Week", :monthly_occurance => 4.333

AllocationMethod.create! :income_frequency_id => 1, :name => "Each paycheck", :monthly_occurance => 2, :is_default => true, :description => "Every time you get paid you will allocate the income."
AllocationMethod.create! :income_frequency_id => 1, :name => "Once a month", :monthly_occurance => 1, :is_default => false, :description => "You will allocate a full month's worth of income at the same time, which will include 2 checks."

AllocationMethod.create! :income_frequency_id => 2, :name => "Each paycheck, twice a month", :monthly_occurance => 2, :is_default => true, :description => "You will allocate each time you get paid, twice a month.  The 2 months each year you receive a 3rd check, it will be considered 'extra' and can be allocated separately."
AllocationMethod.create! :income_frequency_id => 2, :name => "Once a month, 2 per month", :monthly_occurance => 1, :is_default => false, :description => "You will allocate a full month's worth of income at the same time, which will include 2 checks.  The 2 months each year you receive a 3rd check, it will be considered 'extra' and will be allocated separately."
AllocationMethod.create! :income_frequency_id => 2, :name => "Each paycheck", :monthly_occurance => 2.16666, :is_default => false, :description => "You will allocate each time you get paid.  A special '3rd check' allocation plan will be created and will only count 1/6 (one sixth) toward your monthly budget since you will only get a 3rd check 2 months each year."

AllocationMethod.create! :income_frequency_id => 3, :name => "Once a month", :monthly_occurance => 1, :is_default => true

AllocationMethod.create! :income_frequency_id => 4, :name => "Each paycheck", :monthly_occurance => 4.33333, :is_default => true, :description => "You will allocate each time you get paid.  A special '5th check' allocation plan will be created and will only count 1/3 (one third) toward your monthly budget since you will only get a 5th check 4 months each year."
AllocationMethod.create! :income_frequency_id => 4, :name => "Each paycheck, 4 per month", :monthly_occurance => 4, :is_default => false, :description => "You will allocate each time you get paid, four times a month.  The 4 months each year you receive a 5th check, it will be considered 'extra' and can be allocated separately."
AllocationMethod.create! :income_frequency_id => 4, :name => "Once a month, 4 per months", :monthly_occurance => 1, :is_default => false, :description => "You will allocate a full month's worth of income at the same time, which will include 4 checks.  The 4 months each year you receive a 5th check, it will be considered 'extra' and will be allocated separately."

AutoImportMethod.create! :name => "ofx"
AutoImportMethod.create! :name => "scrape"

Bank.create! :name => 'Bank Of America', :ofx_fid => '6812', :ofx_org => 'HAN', :ofx_uri => 'https://ofx.bankofamerica.com/cgi-forte/fortecgi?servicename=ofx_2-3&pagename=ofx', :import_id => '472', :auto_import_method_id => 2, :active => true, :featured => true
Bank.create! :name => 'Chase', :ofx_fid => '10898', :ofx_org => 'B1', :ofx_uri => 'https://ofx.chase.com', :import_id => '636', :auto_import_method_id => 1, :active => true, :featured => true
Bank.create!(:name => 'Capital One 360', :ofx_fid => '031176110', :ofx_org => 'ING DIRECT', :ofx_uri => 'https://ofx.capitalone360.com/OFX/ofx.html', :import_id => '783', :auto_import_method_id => 1, :active => true, :featured => true,
	:notes => "Capital One 360 requires you to first setup an 'Access Code' before you can begin to automatically download transactions.  More information can be found here: <a target='_blank' href='http://helpcenter.capitalone360.com/Topic.aspx?category=FINANCE1#PFAC3'>Personal Finance Access Code</a>")
Bank.create!(:name => 'ING DIRECT', :ofx_fid => '031176110', :ofx_org => 'ING DIRECT', :ofx_uri => 'https://ofx.ingdirect.com/OFX/ofx.html', :import_id => '658', :auto_import_method_id => 1, :active => true, :featured => true,
	:notes => "ING DIRECT requires you to first setup an 'Access Code' before you can begin to automatically download transactions.  More information can be found here: <a target='_blank' href='http://helpcenter.capitalone360.com/Topic.aspx?category=FINANCE1#PFAC3'>Personal Finance Access Code</a>")
Bank.create! :name => 'Wells Fargo', :ofx_fid => '3000', :ofx_org => 'WF', :ofx_uri => 'https://ofxdc.wellsfargo.com/ofx/process.ofx', :import_id => '473', :auto_import_method_id => 2, :active => true, :featured => true
