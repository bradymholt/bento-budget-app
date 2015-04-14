class MonthlyOccurancePrecision < ActiveRecord::Migration
  def change
  	change_column :allocation_methods, :monthly_occurance, :decimal, precision: 6,  scale: 5
  	change_column :income_frequencies, :monthly_occurance, :decimal, precision: 6,  scale: 5

  		drop_table :allocation_methods
	  	create_table "allocation_methods", force: true do |t|
		    t.string   "name"
		    t.string   "description"
		    t.integer  "income_frequency_id"
		    t.decimal  "monthly_occurance",   precision: 6, scale: 5
		    t.boolean  "is_default"
		    t.datetime "created_at"
		    t.datetime "updated_at"
	 	 end

 	AllocationMethod.create! :income_frequency_id => 1, :name => "Each paycheck", :monthly_occurance => 2, :is_default => true, :description => "Every time you get paid you will allocate the income."
AllocationMethod.create! :income_frequency_id => 1, :name => "Once a month", :monthly_occurance => 1, :is_default => false, :description => "You will allocate a full month's worth of income at the same time, which will include 2 checks."

AllocationMethod.create! :income_frequency_id => 2, :name => "Each paycheck, twice a month", :monthly_occurance => 2, :is_default => true, :description => "You will allocate each time you get paid, twice a month.  The 2 months each year you receive a 3rd check, it will be considered 'extra' and can be allocated separately."
AllocationMethod.create! :income_frequency_id => 2, :name => "Once a month, 2 per month", :monthly_occurance => 1, :is_default => false, :description => "You will allocate a full month's worth of income at the same time, which will include 2 checks.  The 2 months each year you receive a 3rd check, it will be considered 'extra' and will be allocated separately."
AllocationMethod.create! :income_frequency_id => 2, :name => "Each paycheck", :monthly_occurance => 2.16666, :is_default => false, :description => "You will allocate each time you get paid.  A special '3rd check' allocation plan will be created and will only count 1/6 (one sixth) toward your monthly budget since you will only get a 3rd check 2 months each year."

AllocationMethod.create! :income_frequency_id => 3, :name => "Once a month", :monthly_occurance => 1, :is_default => true

AllocationMethod.create! :income_frequency_id => 4, :name => "Each paycheck", :monthly_occurance => 4.33333, :is_default => true, :description => "You will allocate each time you get paid.  A special '5th check' allocation plan will be created and will only count 1/3 (one third) toward your monthly budget since you will only get a 5th check 4 months each year."
AllocationMethod.create! :income_frequency_id => 4, :name => "Each paycheck, 4 per month", :monthly_occurance => 4, :is_default => false, :description => "You will allocate each time you get paid, four times a month.  The 4 months each year you receive a 5th check, it will be considered 'extra' and can be allocated separately."
AllocationMethod.create! :income_frequency_id => 4, :name => "Once a month, 4 per months", :monthly_occurance => 1, :is_default => false, :description => "You will allocate a full month's worth of income at the same time, which will include 4 checks.  The 4 months each year you receive a 5th check, it will be considered 'extra' and will be allocated separately."
	
	IncomeFrequency.find(2).update_attributes(:monthly_occurance => 2.16666)
	IncomeFrequency.find(4).update_attributes(:monthly_occurance => 4.333)
  end
end
