var TransactionFilters = {
	init : function() {
		$('#filters-table tbody').on('click', 'a.delete', function(){
			$(this).closest('tr').hide().find('input.destroy').val('1');
		});

		$('#filters-addnew').click(function(){
			var new_filter = $('#filters-table tr.template').last().clone();
			var index = new Date().getTime();
			new_filter.removeClass('template');
			$('input.destroy', new_filter).attr('value', '').val('');
			$('input,select', new_filter).each(function () {
				var name = $(this).attr('name');
				var new_name = name.replace(/\[\d\]/, "[" + index + "]");
				$(this).removeAttr('id').attr('name', new_name);
			});
			new_filter.appendTo('#filters-table tbody');
		
			$('#filters-container')[0].scrollTop = $('#filters-container')[0].scrollHeight;
			$('#filters-container tr input.search_text').last().focus();
		});
	}
};