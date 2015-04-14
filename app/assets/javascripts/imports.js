var ImportForm = {
	allowIFrameLoadContentReplacement : false,
	init : function() {
		$('#new_transaction_file_import').submit(function(e){
			e.stopPropagation();
			ImportForm.allowIFrameLoadContentReplacement = true;
		});

		$('#transaction_file_import_account_id').change(function(){
			var date = $(this).find("option:selected").attr("data-initial_balance_date");
			if (date !== undefined) {
				$("#initial_balance_date").text(date);
				$("#initial_balance_date_notice").show();
			} else {
				$("#initial_balance_date_notice").hide();
			}
		});

		 $('#new_transaction_file_import_iframe').load(function () {
		 	if (ImportForm.allowIFrameLoadContentReplacement == true){
		 		ImportForm.allowIFrameLoadContentReplacement = false;
	 		 	$('#modal').html($("#new_transaction_file_import_iframe").contents().find("html").html()).scrollTop(0).find('.alert-error').effect('bounce');
      		 }
         });
	}
};

var LinkedImportForm = {
	init: function(linked_account_count){
		var buttons = [];
		if (linked_account_count > 0){
			buttons.push({ text: "Update", class: 'btn btn-success', click: function() { LinkedImportForm.startLinkedImport(); } });
		}
		buttons.push({ text: "Close", class: 'btn', click: function() { $(this).dialog("close"); } });
		Common.setModalButtons(buttons);
	},
	startLinkedImport: function(){
		var linked_data = [];
		$('#import_linked_table tbody tr').each(function(index){
			if ($(this).find('input.include').prop('checked') == true) {
				$(this).find('.last_update').addClass('.loading').text('Updating...');
				linked_data.push({id: $(this).attr('account_id'), password: $(this).find('input.password').val() });
			}
		});

		$('#import_linked_wait').text('Updating linked accounts.  Please wait...').show();

		$.ajax({
		  url: '/imports/linked_import_start',
		  type:"POST",
		  data: JSON.stringify({accounts: linked_data}),
		  contentType:"application/json; charset=utf-8",
		  dataType:"html"
		}).done(function(xhr){
			Main.handle_json_response({ success: { refresh: ["envelopes","accounts"] } });
		}).always(function(xhr) { 
			$('#import_linked_wait').hide();
			$('#linked_accounts').html(xhr.responseText || xhr);
		});
	}
};