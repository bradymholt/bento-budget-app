var Main = {
	mainLayout: null,
	init: function(){
		Common.init();

		$('#modal').on('submitSuccess', 'form', function(event, data){
			Main.handle_json_response(data);
		});
		
		EnvelopesList.init();
		AccountsList.init();
		TransactionsList.init();

		Main.mainLayout = $('body').layout({
			north__size:	'45',
			west__size:		'250',
			north__spacing_open :0
		});

		var sidebarLayout = $('#sidebar').layout({
			south__size:	'125',
		});
	},
	handle_json_response: function(data){
		if (data.success !== undefined){
			if (data.success.notice !== undefined){
				$('#bottom-alert').removeClass('alert-error').addClass('alert-success').text(data.success.notice).parent().show().fadeOut(10000, function(){
					$(this).hide();
				});
			}

			if (data.success.envelopes !== undefined){
				EnvelopesList.update(data.success.envelopes);
			}

			if (data.success.accounts !== undefined){
				AccountsList.update(data.success.accounts);
			}

			if (data.success.refresh !== undefined){
				if (!$.isArray(data.success.refresh)){
					data.success.refresh = data.success.refresh.split();
				}

				$.each(data.success.refresh, function( index, value ) {
					switch(value) {
						case 'transactions':
							TransactionsList.refresh();
							break;
						case 'envelopes':
							EnvelopesList.refresh();
							break;
						case 'accounts':
							AccountsList.refresh();
							break;
					}
				});
			}

			if (data.success.navigate !== undefined){
				if (data.success.navigate.modal === true){
					Common.openModalLink(data.success.navigate.href, data.success.navigate.title, data.success.navigate.button_text);
				} else {
					document.location.href = data.success.navigate.href;
				}
			}
		}

		if (data.error !== undefined){
			if (data.error.notice !== undefined){
				$('#alert-error').text(data.error.notice).show().fadeOut(10000);
			}
		}
	},
	updateTotals: function(transaction_amt, envelope_amts, total_target, remaining_target){
		var allocated = Common.getSum(envelope_amts);
		total_target.text(Common.formatMoney(allocated));

		var remaining = Math.abs(parseFloat(transaction_amt.replace(',', ''))) - allocated;
		remaining_target.text(Common.formatMoney(remaining, true));

		if (remaining < 0) {
			remaining_target.prev().text('Overallocated Amount:').removeClass('positive').addClass('negative');
		}
		else{
			remaining_target.prev().text('Remaining Amount:').removeClass('negative').addClass('positive');
		}

		return remaining;
	}
};