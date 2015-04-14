var IncomeForm = {
	init: function(){
		$('#income_income_frequency_id option').click(function(){
			IncomeForm.setupAllocateMethods();
			//uncheck all all and check the default for the current income frequency
			$('#income_allocation_method input').prop('checked', false);
			$('#income_allocation_method label[income_frequency_id="' + $(this).val() + '"] input[default="true"]').prop('checked', true);
			
			IncomeForm.setupAllocationGroup();
		});

		$('#income_allocation_method input[name="income[allocation_method_id]"').change(function(){
			IncomeForm.setupAllocationGroup();
		});

		if ($('#income_income_frequency_id option:selected').val() !== undefined){ //for edit
			IncomeForm.setupAllocateMethods();
			IncomeForm.setupAllocationGroup();
		}
	},
	setupAllocateMethods: function(){
		$('#income_allocation_method label').hide();
		var selected_income_income_frequency_id = $('#income_income_frequency_id option:selected').val();
		var available_allocation_methods = $('#income_allocation_method label[income_frequency_id="' + selected_income_income_frequency_id + '"]');
		available_allocation_methods.show();
		if (available_allocation_methods.length > 1) {
			$('#income_allocation_method').show();
		} else {
			$('#income_allocation_method').hide();
		}
	},
	setupAllocationGroup: function(){
		var group_income = $('select#income_allocation_method_grouped_with_income_id');
		$('option[value != ""]', group_income).prop('disabled', true);
		var selected_allocation_method_id = $('#income_allocation_method input:checked').val();
		var available_group_incomes = $('option[income_allocation_method_id="' + selected_allocation_method_id + '"]', group_income);
		available_group_incomes.prop('disabled', false);

		if (available_group_incomes.length > 0){
			$('#income_allocation_grouping').show();

			if (available_group_incomes.length == 1){
				//only 1 available so select it by default
				group_income[0].selectedIndex = 1;
			}
		} else{
			$('#income_allocation_grouping').hide();
		}
	}
};