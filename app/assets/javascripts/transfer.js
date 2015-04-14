var Transfer = {
	init: function(isNew){
		$('#date').datepicker({dateFormat: 'mm/dd/yy', altField: '#transfer_date', altFormat: 'yy-mm-dd'});

		if (isNew){
			$('#transfer_from_envelope_id').first().val(EnvelopesList.currentEnvelopeID);
		}
	}
};