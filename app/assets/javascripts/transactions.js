var TransactionsList = {
	currentTransactionsUri : '',
	mouseDownSelected : false,
	init : function(){
		$('#transactions-list').on('click', 'tbody tr', function(e){
			if($(this).hasClass('ui-selected') && !TransactionsList.mouseDownSelected){
				$(this).removeClass('ui-selected');
			}
		});

		$('#transactions-list').on('mousedown', 'tbody tr', function(e){
			TransactionsList.mouseDownSelected = false;

			if(!$(this).hasClass('ui-selected')){
				$(this).addClass('ui-selected');
				TransactionsList.mouseDownSelected = true;
			}
		});

		$('#btn-edit').click(function(){
			var firstSelected = $('#transactions-list tbody tr.ui-selected').first();
			if (firstSelected.length == 1){
				$('#transactions-list tbody tr.ui-selected').not(firstSelected).removeClass('ui-selected');
				TransactionsList.edit(firstSelected.attr('transaction_id'));
			}
		});

		$('#transactions-list').on('dblclick', 'tbody tr', function(e){
			$('#transactions-list tbody tr.ui-selected').removeClass('ui-selected');
			$(this).addClass('ui-selected');
			TransactionsList.edit($(this).attr('transaction_id'));
		});	

		$('#days').change(function(){
			TransactionsList.refresh();
		});

		$('#btn-allocate').click(function(){
			$(this).attr('href', $(this).attr('href').split('?')[0]); //reset
			var selected_transaction_ids = $('#transactions-table .allocate_check:checked').closest('tr').map(function(){ return $(this).attr('transaction_id'); } ).get();
			if (selected_transaction_ids.length > 0) {
				$(this).attr('href', $(this).attr('href') + '?ids=' + selected_transaction_ids.join() );
			}
		});
	},
	edit: function(id){	
		Common.openModalLink('/transactions/' + id + '/edit', 'Edit Transaction');
	},
	refresh: function(){
		TransactionsList.loadByUri(TransactionsList.currentTransactionsUri);
	},
	load : function(id, type) {
		var uri = '/envelopes/' + id + '/transactions';
		if (type == 'account') {
			uri = '/accounts/' + id + '/transactions';
		}

		TransactionsList.loadByUri(uri);
	},
	loadByUri : function(uri) {
		$('#transactions-list').empty();
		$('#transactions-list').addClass('loading');

		var daysQuery = $('#days').val() != '' ? ('/?days=' + $('#days').val()) : ('');
		$('#transactions-list').load(uri + daysQuery, function(){
			$('#transactions-list').removeClass('loading');
			$('#transactions-table tbody tr').draggable({
				helper: function() {
					return $("<table></table>")
					.append(
						$(this).closest("tbody")
						.find("tr.ui-selected").clone())[0];
				},
				appendTo: "body"
			});

			if ($('#envelopes li.envelope.ui-selected.unallocated-income').length == 1 && $('#transactions-table tbody tr').length > 0){
				$('#btn-allocate').show();
			}
			else{
				$('#btn-allocate').hide();
			}

			$('#transactions-table').disableSelection().stupidtable();
		});

		TransactionsList.currentTransactionsUri = uri;
	}
};

var TransactionForm = {
		init: function(isNew){
			$('#date').datepicker({dateFormat: 'mm/dd/yy', altField: '#transaction_date', altFormat: 'yy-mm-dd'});
			$('.type_button').click(function(){
				$('.type_button').removeClass('btn-danger btn-success btn-primary');
				$(this).addClass($(this).attr("data-active-class"));
				$('#transaction_transaction_type').val($(this).attr('data-value'));
				if ($(this).attr('id') == "type_income"){
					$("#transaction-envelope-amounts").hide();
					$("#transaction-envelope-amounts-add").hide();
					$('#income_instructions').show();
				} else {
					$("#transaction-envelope-amounts").show();
					$("#transaction-envelope-amounts-add").show();
					$('#income_instructions').hide();
				}
			});

			$('.type_button[data-value="' + $('#transaction_transaction_type').val() + '"]').click();
			
			$('form#new_transaction,form.edit_transaction').submit(function(){
				var envelope_amounts = $('#transaction-envelope-amounts tbody tr')
				.map(function(){
					return { envelope_id: $(this).find('select.envelope').val(), notes: $(this).find('input.notes').val(), amount: $(this).find('input.money').val() };
				}).get();

				$('#transaction_envelope_amounts').val(JSON.stringify(envelope_amounts));
			});

			$('#transaction-envelope-amounts-add').click(function(){
				var newRow = $('#transaction-envelope-amounts tbody tr:last').clone();
				$('#transaction-envelope-amounts tbody').append(newRow);
				$('a.remove', newRow).show();
				$('input, select', newRow).val('');
				$('input.money', newRow).val('0.00');

				TransactionForm.setupEnvelopeAmounts();

				$('#transaction-envelope-amounts-container')[0].scrollTop = $('#transaction-envelope-amounts-container')[0].scrollHeight;
				
				if ($('#transaction-envelope-amounts tbody tr').length == 2){
					$('#transaction-envelope-amounts tbody input.money').first().select();
				}
				else{
					$('.envelope', newRow).focus();
				}
			});

			$('#transaction-envelope-amounts tbody').on('click', 'a.remove', function(){
				$(this).closest('tr').remove();
				TransactionForm.setupEnvelopeAmounts();
			});

			$('#transaction-envelope-amounts tbody').on('blur', 'input.money', function(){
				var remaining = TransactionForm.updateTotals();
				if (remaining > 0 && $(this).closest('tr').next().length > 0){ //not last row
					var next = $('input.money', $(this).closest('tr').next());
					if (next.val() === '' || parseFloat(next.val()) === 0) {
						next.val(Common.formatMoney(remaining, true));
						TransactionForm.updateTotals();
					}
				}	
			});

			$('#transaction-envelope-amounts tbody tr a.remove').first().hide(); //do not allow remove of first amount
			$('#transaction-envelope-amounts tbody .envelope').first().focus(); //focus first envelope 

			TransactionForm.updateTotals();
			TransactionForm.setupEnvelopeAmounts();	

			if (isNew){
				if (EnvelopesList.currentEnvelopeID !== null) {
					$('#transaction-envelope-amounts select.envelope').first().val(EnvelopesList.currentEnvelopeID);
				}

				if (AccountsList.currentAccountID !== null) {
					$('select#transaction_account_id').val(AccountsList.currentAccountID);
				}

				Common.setModalButtons([
					{ text: "Save", class: "btn btn-success", click: function(){ $('form', $(this)).submit(); } },
					{ text: "Save & Add Another", class: "btn btn-success", click: function(){ 
							$('#modal').on('submitSuccess', 'form#new_transaction', function(event){
								$('#btn-new-transaction').click(); 
							});

							$('form', $(this)).submit(); 
						} 
					},
					{ text: "Cancel", class: "btn", click: function() { $(this).dialog("close"); } }
				]);
			}	
		},
		updateTotals: function(){
			return Main.updateTotals($('#transaction_amount').val(), $('#transaction-envelope-amounts tbody input.money'), $('#total-allocated'), $('#remaining-allocated'));
		},
		setupEnvelopeAmounts: function(){
			if ($('#transaction-envelope-amounts tbody tr').length == 1) {
				$('#transaction-envelope-amounts th:nth-child(3), #transaction-envelope-amounts td:nth-child(3)').hide();
				$('#transaction-totals').hide();
				
				$('#transaction-envelope-amounts tbody tr .money').val(Common.formatMoney($('#transaction_amount').val(),true));
			}
			else {
				$('#transaction-envelope-amounts th:nth-child(3), #transaction-envelope-amounts td:nth-child(3)').show();
				$('#transaction-totals').show();
			}
		}
};