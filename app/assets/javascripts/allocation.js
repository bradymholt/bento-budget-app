var AllocationForm = {
		init: function(){
			$('#date').datepicker({
				dateFormat: 'mm/dd/yy', 
				altField: '#allocation_date', 
				altFormat: 'yy-mm-dd',
				onSelect:function(dateText){
					AllocationForm.getFundedAmounts();
				}
			});

			$('form#new_allocation,form.edit_allocation').submit(function(){
				var envelope_amounts = $('input.money', $(this))
				.filter(function () { return $(this).val() !== ''; })
				.map(function(){
					return { envelope_id: $(this).attr('envelope_id'), amount:  $(this).val() };
				}).get();

				$('#allocation_envelope_amounts').val(JSON.stringify(envelope_amounts));
			});

			$('#btn-plans-fill').click(function(){
				$('#allocation-envelope-amounts-container input.money').val(''); //clear all
			 	$.getJSON('/allocation_plans/' + $("#plans").val() + '/allocation_plan_items/', function(result) {
					 $.each(result, function(i, item){
					 	var amt = Common.formatMoney(item.amount, true);
					 	$('#allocation-envelope-amounts-container input[envelope_id="' + item.envelope_id + '"]').val(amt);
		    		});

					AllocationForm.updateTotals();
				});

				return false;
			 });

			$('.fund_remaining').click(function(){
				var envelope_row = $(this).closest('tr');
				$('.money', envelope_row).val($('.remaining', envelope_row).text());
				AllocationForm.updateTotals();
			});

			$('form#new_allocation input.money,form.edit_allocation input.money').blur(function(){
				AllocationForm.updateTotals();
			});


			AllocationForm.getFundedAmounts();
			AllocationForm.updateTotals();
		},
		updateTotals: function(){
			Main.updateTotals($('#allocation_amount').text(), $('form#new_allocation input.money,form.edit_allocation input.money'), $('#total-allocated'), $('#remaining-allocated'));
		},
		getFundedAmounts: function(){
			$.getJSON('/envelopes/funded_amounts/?date=' + $('#allocation_date').val(), function(result){
				$('#allocation-envelope-amounts-container th#funded-header').html('Allocated in<br/>' + result.month_name);
				$('#allocation-envelope-amounts-container td.funded, #allocation-envelope-amounts-container td.remaining').text('0.00');
				$.each(result.funded_amounts, function(i, item){
					$('#allocation-envelope-amounts-container tr[envelope_id="' + item.envelope_id + '"] td.funded').text(parseFloat(item.amount).toFixed(2));
				});

				AllocationForm.updateRemainingAmounts();
			});
		},
		updateRemainingAmounts: function(){
			$('#allocation-envelope-amounts-container tbody tr:not(.group)').each(function(i, item) {
				var budget = $('td.budget', $(item));
				var funded = $('td.funded', $(item));
				var remaining = $('td.remaining', $(item));
				var fund_with_remaining = $('.fund_remaining', $(item));

				var remaining_amount = (parseFloat(budget.text()) - parseFloat(funded.text())).toFixed(2);
				
				if (remaining_amount > 0){
					remaining.text(remaining_amount);
					remaining.addClass('negative');
					fund_with_remaining.show();
				} else {
					remaining.text('--');
					remaining.removeClass('negative');
					fund_with_remaining.hide();
				}
			});
		}
	};