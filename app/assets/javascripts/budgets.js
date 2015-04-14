var Budget = {
	init: function(){
		Common.init();

		Main.mainLayout = $('body').layout({
			north__size:	'45',
			west__size:		'250',
			north__spacing_open :0
		});

		$('div.income').click(function(){
			Common.openModalFromAnchor($(this).find('a.edit'));
		});

		$('#modal').on('submitSuccess', 'form', function(event, data){
			location.reload(true);
		});

		$('#budget').on('blur', '.budget input.money', function(){
			Budget.save($(this), '/budgets/envelopes/' + $(this).closest('tr').attr('envelope_id'), 'Budget');
		});

		$('#budget').on('blur', '.plan input.money', function(){
			Budget.save($(this), '/allocation_plans/' + $(this).attr('plan_id') + '/envelopes/' + $(this).closest('tr').attr('envelope_id'), 'Allocation');
		});

		Budget.updateDiffs();
	},
	save: function(input, url, description){
		$.ajax({
	        type: 'PUT',
	        url:  url,
	        contentType: 'application/json',
	        data: JSON.stringify( { amount: input.val() } ),
	        dataType: "json",
	        success: function(data) {
	        	input.val(Common.formatMoney(data.amount, true));
	        	Budget.showSuccessMessage(description + ' amount successfully saved.');
	        	Budget.updateEnvelopeDiff(input.closest('tr'));

	        	if (input.attr('plan_id') !== undefined){
	        		Budget.updatePlanDiff(input.attr('plan_id'));
	        	} else {
	        		Budget.updateBudgetDiff();
	        	}
	        }
    	});
	},
	showSuccessMessage: function(text){
		$('#bottom-alert').text(text).parent().stop(true,true).show().fadeOut(2000, function(){
			$(this).hide();
		});
	},
	updateDiffs: function(){
		$('#budget tbody tr.envelope').each(function() {
			Budget.updateEnvelopeDiff($(this));
		});

		$('#budget thead th.plan').each(function() {
			Budget.updatePlanDiff($(this).attr('plan_id'));
		});

		Budget.updateBudgetDiff();
	},
	updatePlanDiff: function(plan_id) {
		var plan_amt = parseFloat($('#budget thead th.plan[plan_id="' + plan_id + '"] span.plan-total').text().replace(',',''));
		var plan_sum = Common.getSum($('#budget tbody tr.envelope td.plan input.money[plan_id="' + plan_id + '"]'));
		var diff_amt = (plan_sum - plan_amt);
		
		$('#budget tfoot tr.amount td.plan[plan_id="' + plan_id + '"]').text(Common.formatMoney(plan_amt));
		$('#budget tfoot tr.sum td.plan[plan_id="' + plan_id + '"]').text(Common.formatMoney(plan_sum));
		Budget.printDiff(diff_amt, $('#budget tfoot tr.diff td.plan[plan_id="' + plan_id + '"]'));
	},
	updateEnvelopeDiff: function(envelopeRow){
		var envelope_plan_sum = 0;

		var envelope_budget_amt = parseFloat($('.budget input.money', envelopeRow).val());
		var plan_count = $('#budget th.plan').length;
		$('.plan input.money', envelopeRow).each(function(){
			var amt = $(this).val();
			if (amt === '') {
				var calculated_plan_amt = ((envelope_budget_amt / plan_count) * parseFloat($(this).attr('monthly_occurance')));
				$(this).val(Common.formatMoney(calculated_plan_amt));
				envelope_plan_sum += calculated_plan_amt;
			}
			else if (!isNaN(amt)) {
				envelope_plan_sum += (parseFloat(amt) * parseFloat($(this).attr('monthly_occurance')));
			}
		});
		var diff_amt = (envelope_plan_sum - envelope_budget_amt);
		Budget.printDiff(diff_amt, $('.diff', envelopeRow));
	},
	updateBudgetDiff: function(){
		var budget_amt = parseFloat($('#budget thead th.budget span.budget-total').text().replace(',',''));
		var budget_sum = Common.getSum($('#budget tbody tr.envelope td.budget input.money'));
		var diff_amt = (budget_sum - budget_amt);

		$('#budget tfoot tr.amount td.budget').text(Common.formatMoney(budget_amt));
		$('#budget tfoot tr.sum td.budget').text(Common.formatMoney(budget_sum));
		Budget.printDiff(diff_amt, $('#budget tfoot tr.diff td.budget'));
	},
	printDiff: function(diff_amt, diff_element) {
		if (diff_amt == 0){
			diff_element.html('<div class="green-check"></div>');
		}
		else if (diff_amt > 0) {
			diff_element.text("+" + Common.formatMoney(diff_amt));
		}
		else {
			diff_element.text(Common.formatMoney(diff_amt));
		}
	}
};