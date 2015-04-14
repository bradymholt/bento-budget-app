var Common = {
	init: function(){
		$('body').on('blur', '.money', function(){
			$(this).val(Common.formatMoney($(this).val(), !$(this).hasClass('noAbs')));
		});

		$('body').on('click', '.money', function(){
			$(this).select();
		});

		Common.initModal();
	},
	initModal: function(){
		var dlg = $('#modal');
		dlg.dialog({
			autoOpen: false,
			position: ['center', 20],
			top: '20',
			width: '750',
			modal: true
		});

		dlg.keypress(function(e) {
			if (e.keyCode == 13) {
				$('.ui-dialog-buttonset button').first().click();
				return false;
			}
		});

		$('.ui-dialog').on('mouseover', '.ui-dialog-buttonset button', function(e){
			$(this).removeClass("ui-state-hover"); //prevent jquery ui button styles
		});

		$('body').on('click', 'a.open-modal', function(e){
			Common.openModalFromAnchor($(this));
			return false;
		});

		dlg.on('submit', 'form', function(e){
			var form = $(this);
			$.ajax({
				url: form.attr("action"),
				type: form.attr("method"),
				data: form.serialize(),
				beforeSend:function(data){
    			  dlg.prepend('<div class="alert alert-info">Saving, please wait...</div>');
    			}
			}).done(function(data) { 
				dlg.dialog('close');
				form.trigger('submitSuccess', data);
			}).fail(function(xhr) { 
			  	dlg.html(xhr.responseText).scrollTop(0).find('.alert-error').effect('bounce');
			  	form.trigger('submitFail');
			});

			e.preventDefault();
		});
	},
	formatMoney:function(input, abs){
		if (input === '') {
			return '';
		}
		else {
			input = isNaN(input) || input === '' || input === null ? 0.00 : input;
			if (abs){
				input = Math.abs(input)
			}
			formatted = parseFloat(input).toFixed(2);
			return formatted;
		}
	},
	getSum:function(selector){
		var sum = 0;
		selector.filter(function () { return $(this).val() !== ''; }).each(function(){
			var amt = $(this).val();
			if (!isNaN(amt) ){
				sum += Number(amt);
			}
		});

		return Number(sum.toFixed(2));
	},
	openModalFromAnchor: function(anchor_element){
		var title = anchor_element.attr('data-title') !== undefined ? anchor_element.attr('data-title') : anchor_element.text();
		var button_text = anchor_element.attr('data-button');
		var href = anchor_element.attr('href');
		if (href.indexOf('#') == 0){
			Common.openModal($(href).html(), title, button_text);
		}
		else{
			Common.openModalLink(href, title, button_text);
		}
	},
	openModal:function(content, title, button_text){
		if (button_text === undefined){
			button_text = 'Close';
		}

		$('#modal').html(content)
		 .dialog('option', 'title', title)
		 .dialog('open');

		 Common.setModalButtons([
				{ text: button_text, class: "btn", click: function() { $(this).dialog("close"); } }
			]);
	},
	openModalLink:function(url, title, button_text){
		if (button_text === undefined){
			button_text = 'Save';
		}

		var dlg = $('#modal')
		dlg.html('<div class="loading"></div>')
		 .dialog('option', 'title', title)
		 .dialog('open')
		 .load(url, function(){
				$('select,input:not(:hidden):not(.date)', dlg).first().focus();
		 });

		 Common.setModalButtons([
				{ text: button_text, class: "btn btn-success", click: function(){ $('form', $(this)).submit(); } },
				{ text: "Cancel", class: "btn", click: function() { $(this).dialog("close"); } }
			]);
	},
	setModalButtons:function(buttons){
		$('#modal').dialog('option', 'buttons', buttons);
		$('.ui-dialog-buttonset button').removeClass('ui-button ui-widget ui-state-default ui-corner-all ui-button-text-only'); //allow bootstrap style
	},
	setupCheckboxInputDependency: function(checkbox, container){
		var input = $('input,select', container).first();
		var defaultValue = input.attr('data-default') || input.val();
		
		Common.checkboxInputDependencyRefresh(checkbox, container, input);

		checkbox.change(function(){
			if ($(this).prop('checked')){
				input.val(defaultValue);
				container.show();
			}
			else{
				input.val('');
				container.hide();
			}
		});
	},
	checkboxInputDependencyRefresh: function(checkbox, container, input){
		var hasValue = input.val() != '';	
		checkbox.prop('checked', hasValue); 
		container.css('display', hasValue ? 'block' : 'none' );
	}
};