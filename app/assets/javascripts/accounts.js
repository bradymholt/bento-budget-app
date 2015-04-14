var AccountManualNewForm = {
	init: function(){
		$('#new_account_date').datepicker({dateFormat: 'mm/dd/yy', altField: '#account_initial_balance_date', altFormat: 'yy-mm-dd'});
	}
};

var AccountEditForm = {
	init: function(){
		$('#transaction_date').datepicker({dateFormat: 'mm/dd/yy', altField: '#account_initial_balance_date', altFormat: 'yy-mm-dd'});
		$('#unlink-account').click(function(){
			$('#account_bank_id').val('');
			$(this).hide();
			$('#linked-fields').hide();
		});
	}
}

var AccountLinkedForm = {
	isNew: false,
	init: function(isNew){
		AccountLinkedForm.isNew = isNew;
		$('#new_account_date').datepicker({dateFormat: 'mm/dd/yy', altField: '#account_initial_balance_date', altFormat: 'yy-mm-dd'});

		$('#account_bank_id').change(function(){
			var selected_option = $('#account_bank_id option:selected');
			$('#bank_standard_ofx_note, #bank_notes').hide();

			if (selected_option.attr("notes") == "true") {
				$.getJSON("banks/" + $(this).val() + "/notes", function( data ) {
					$('#bank_notes').html(data.notes).show();
				});
			} else if (selected_option.attr("ofx") == "true") {
				$('#bank_standard_ofx_note').show();
			} 
		});

		$('form#linked_account').submit(function(e){
			var form = $(this);
			$.ajax({
				url: form.attr("action"),
				type: form.attr("method"),
				data: form.serialize(),
				beforeSend:function(data){
    			  $('#modal').html('<div class="loading">Saving...</div>');
    			}
			}).done(function(data) { 
				$('#modal').dialog('close');
				Main.handle_json_response(data);
			}).fail(function(xhr) { 
			  	$('#modal').html(xhr.responseText).scrollTop(0).find('.alert-error').effect('bounce');
			  	$('#linked_account_bank_info').hide();
				$('#linked_account_confirm').show();
			});

			e.preventDefault();
		});

		AccountLinkedForm.linkedAdvanceToBankInfo();
	},
	linkedAdvanceToBankInfo: function(){
		 $('form#linked_account fieldset').hide();
		 $('#linked_account_bank_info').show();

		Common.setModalButtons([
				{ text: "Next", class: 'btn btn-success', click: function() { AccountLinkedForm.linkedAdvanceToAccounts(); } },
				{ text: "Cancel", class: 'btn', click: function() { $(this).dialog("close"); } } 
			]);

	},
	linkedAdvanceToAccounts: function(){
		$('#linkedaccount_error').hide();
		
		if ($('#account_bank_id').val() == "") {
			$('#linked_account_error').text("A bank must be selected.").show();
		}
		else if($('#account_linked_user_id').val() == "") {
			$('#linked_account_error').text("A username must be specified.").show();
		}
		else if($('#account_linked_password').val() == "") {
			$('#linked_account_error').text("A password must be specified.").show();
		}
		else{
			$('#linked_account_wait').text('Contacting your bank to get a list of accounts.  Please wait...').show();
			$.post('accounts/linked_bank_accounts', { 
				account_bank_id: $('#account_bank_id').val(), 
				user_id: $('#account_linked_user_id').val(), 
				password: $('#account_linked_password').val(),
				security_answers: $('#account_linked_security_answers').val()
			})
			.done(function( json ) {
				$('#linked_account_wait').hide();

			  	if (json.accounts === undefined || json.accounts.length == 0){
			  		$('#linked_account_error').text('No accounts are available.').show();
			  	}
			  	else {
			  		$('#ofx_bank_accounts').empty();
				  	$.each(json.accounts, function( key, acct ) {
				  		 $('#ofx_bank_accounts').append($('<option>', { 
					        value: acct.account_id,
					        text : acct.description,
					        bank_id : acct.bank_id,
					        account_type : acct.account_type
					     	})
				  		 );
					 });

				  	 //everything is good, do the advance now
				  	 $('form#linked_account fieldset').hide();
					 $('#linked_account_select_account').show();

					 if ( AccountLinkedForm.isNew === true ) {
						 Common.setModalButtons([
							{ text: "Next", class: 'btn btn-success', click: function() { AccountLinkedForm.linkedAdvanceToConfirm(); } },
							{ text: "Go Back", class: 'btn', click: function() { AccountLinkedForm.linkedAdvanceToBankInfo(); } },
							{ text: "Cancel", class: 'btn', click: function() { $(this).dialog("close"); } } 
						]);
					} else {
						Common.setModalButtons([
						  { text: "Finish", class: 'btn btn-success', click: function() { AccountLinkedForm.setSelectedAccountFields(); $('form#linked_account').submit(); } },
						  { text: "Cancel", class: 'btn', click: function() { $(this).dialog("close"); } } 
						]);
					}
			  	}
			})
		    .fail(function( jqxhr, textStatus, error ) {
		    	$('#linked_account_wait').hide();
		    	var response = JSON.parse(jqxhr.responseText);
		  		
		  		if (response.is_security_question_asked === true) {
		  			AccountLinkedForm.linkedAdvanceToSecurityQuestion(response.friendly_error);
		  		} else {
		  			$('#linked_account_error').text(response.friendly_error).show();
		  		}
		  	});
		 }
	},
	linkedAdvanceToSecurityQuestion: function(question){
		$('#linked_account_error').hide();
		$('#security_question').text(question);
		$('#account_linked_security_answers').val('');
		$('form#linked_account fieldset').hide();
		$('#linked_account_security_question').show();

		 Common.setModalButtons([
			{ text: "Next", class: 'btn btn-success', click: function() { AccountLinkedForm.linkedAdvanceToAccounts(); } },
			{ text: "Go Back", class: 'btn', click: function() { AccountLinkedForm.linkedAdvanceToBankInfo(); } },
			{ text: "Cancel", class: 'btn', click: function() { $(this).dialog("close"); } } 
		]);
	},
	linkedAdvanceToConfirm: function(){
		$('#linked_account_error').hide();
		$('#linked_account_wait').text('Contacting your bank to get latest account balance.  Please wait...').show();
		
		var selected_account = $('#ofx_bank_accounts option:selected');

		$.post('accounts/linked_bank_balance', { 
			account_bank_id: $('#account_bank_id').val(), 
			user_id: $('#account_linked_user_id').val(), 
			password: $('#account_linked_password').val(),
			bank_id: selected_account.attr('bank_id'), 
			account_id: selected_account.val(),
			account_type: selected_account.attr('account_type'),
		})
	    .done(function( json ) {
	    	$('#linked_account_wait').hide();

		  	if (json === undefined || json === null){
		  		$('#linked_account_error').text('Account balance could not be retrieved.').show();
		  	}
		  	else {
		  		$('#account_name').val(selected_account.text());
		  		$('#new_account_date').datepicker( "setDate", $.datepicker.parseDate("yy-mm-dd", json.balance_date ) );
		  		$('#account_initial_balance_amount').val(parseFloat(json.balance).toFixed(2));
			  	$('#account_linked_initial_balance_bank_transaction_ids').val(json.balance_transaction_ids);
			  	
			  	AccountLinkedForm.setSelectedAccountFields();
			 
			  	if ($('#save_password').prop('checked') === false) {
			  		$('#account_linked_password').val('');
			  	}

			  	 //everything is good, do the advance now
			  	 $('form#linked_account fieldset').hide();
				$('#linked_account_confirm').show();

				Common.setModalButtons([
				  { text: "Finish", class: 'btn btn-success', click: function() { $('form#linked_account').submit(); } },
				  { text: "Cancel", class: 'btn', click: function() { $(this).dialog("close"); } } 
				]);
		  	}
	  	})
	    .fail(function( jqxhr, textStatus, error ) {
		  	$('#linked_account_wait').hide();
		  	$('#linked_account_error').text(JSON.parse(jqxhr.responseText).friendly_error).show();
		});
	},
	setSelectedAccountFields: function(){
		var selected_account = $('#ofx_bank_accounts option:selected');
		$('#account_linked_account_number').val(selected_account.val());
		$('#account_linked_bank_code').val(selected_account.attr('bank_id'));
		$('#account_account_type').val(selected_account.attr('account_type'));
	}
};

var AccountsList = {
	currentAccountID: null,
	init : function(){
		$('#accounts').on('click', 'li', function(e){
			AccountsList.select($(this).attr('account_id'));
		}).disableSelection();

		$('#accounts').on('dblclick', 'li', function(e){
			Common.openModalLink('/accounts/' + $(this).attr('account_id') + '/edit', 'Edit Account');
		});

		AccountsList.refresh();
	},
	select: function(id){
		$('#envelope-tree li').removeClass('ui-selected');
		AccountsList.currentAccountID = id;
		EnvelopesList.currentEnvelopeID = null;
		var acct = $('#account-tree li.account[account_id=' + id + ']');
		$('#account-tree li.account').not(acct).removeClass('ui-selected');
		acct.addClass('ui-selected');
		TransactionsList.load(id, 'account');
		$('#transactions-title').text(acct.find('.account-name').text());
	},
	refresh: function(handler){
		$('#accounts').load('/accounts/');
	},
	update: function (accounts) {
		$.each(accounts, function(i, item){
			var account = $('#account-tree li[account_id="' + item.id + '"]');
			$('div.account-name', account).text(item.name);
			if (account.hasClass('ui-selected')){
				$('#transactions-title').text(item.name);
			}
			if (item.balance !== undefined) {
				$('.account-balance', account)
					.html(parseFloat(item.balance).toFixed(2))
					.effect('highlight', { color: '#9BFFA3' }, 2000);
			}
		});
	} 
};