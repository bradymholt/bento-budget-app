var EnvelopesList = {
	currentEnvelopeID : null,
	/*scrollTimer: null,*/
	init: function(){		
		$('#envelopes').on('dblclick', '.envelope:not(.global)', function(e){
			Common.openModalLink('/envelopes/' + $(this).attr('envelope_id') + '/edit', 'Edit Envelope');
		});

		$('#envelopes').on('dblclick', '.group-name', function(e){
			Common.openModalLink('/envelope_groups/' + $(this).closest('li').attr('group_id') + '/edit', 'Edit Group');
		});

		/*$(document).mousemove(function(event) {
			//only on dragging!
			//restict X coordinates!

			var envelopePane = $(".ui-layout-center.ui-layout-pane.ui-layout-pane-center")[0];
			var startYPosition = envelopePane.parentElement.offsetTop;
			var visibleHeight = envelopePane.offsetHeight;
			var totalHeight = envelopePane.scrollHeight;

			if (totalHeight > visibleHeight) {
				var targetAbsoluteYStart = (startYPosition + visibleHeight) - 10;
				if (event.pageY >= targetAbsoluteYStart) {
					scrollTimer = setInterval(function(){envelopePane.scrollTop = envelopePane.scrollTop + 1}, 100);
				}
				else {
					clearInterval(scrollTimer);
				}
			}
		});*/

		EnvelopesList.refresh(function(){
			EnvelopesList.select($('#envelopes li.new-transactions').first().attr('envelope_id'));
		});
	},
	refresh: function(handler){
		$('#envelopes').load('/envelopes/', function(){
			$('#envelopes .group-name').click(function() {
				$(this).next().slideToggle();
				return false;
			});

			$('#envelope-tree').sortable({
				update: function(event, ui) {
					neworder = [];
					$(this).children().each(function(idx){
						neworder.push({ id: $(this).attr('group_id'), sort_order: idx  })
					});

					EnvelopesList.reorder('/envelope_groups/reorder', neworder);
				}
			});

			$('.group-envelopes').sortable({
				connectWith: $('.group-envelopes'),
				update: function(event, ui) {
					neworder = [];
					var groupId = $(this).parent().attr('group_id');
					$(this).children().each(function(idx){
						neworder.push({ id: $(this).attr('envelope_id'), group_id: groupId, sort_order: idx  })
					});

					EnvelopesList.reorder('/envelopes/reorder', neworder);
				}
			});

			$('#envelopes li.envelope').droppable({
				tolerance: "pointer",
				accept: "tr.ui-selected",
				hoverClass: "ui-state-hover",
				drop: function( event, ui ) {
					var targetEnvelope = $(this);
					var selected_transaction_ids = $('#transactions-table tr.ui-selected').map(function(){ return $(this).attr('transaction_id'); } ).get();
					
					$.ajax({
						url: '/transactions/assign',
						type: 'POST',
						data: JSON.stringify( { id: selected_transaction_ids, envelope_id: $(this).attr('envelope_id') } ),
						contentType: 'application/json; charset=UTF-8',
					    dataType:"json"
					}).done(function(data){
						Main.handle_json_response(data);
					});

					$('#transactions-table tr.ui-selected').remove();
				}
			}).mousedown(function(){
				EnvelopesList.select($(this).attr('envelope_id'));
			}).disableSelection();

			if (handler && typeof(handler) == 'function') {
				handler();
			}

			if (EnvelopesList.currentEnvelopeID != null) {
				$('#envelopes li.envelope[envelope_id=' + EnvelopesList.currentEnvelopeID + ']').addClass('ui-selected');
			}
		});
	},
	reorder: function(url, new_order) {
		$.ajax({
		  url: url,
		  type:"POST",
		  data: JSON.stringify({ order: new_order }),
		  contentType:"application/json; charset=utf-8",
		  dataType:"json"
		}).done(function(data){
			Main.handle_json_response(data);
		});
	},
	select: function(id){
		$('#account-tree li.account').removeClass('ui-selected');
		AccountsList.currentAccountID = null;
		EnvelopesList.currentEnvelopeID = id;
		var env = $('#envelope-tree li.envelope[envelope_id=' + id + ']');
		$('#envelope-tree li.envelope').not(env).removeClass('ui-selected');
		env.addClass('ui-selected');

		TransactionsList.load(EnvelopesList.currentEnvelopeID); 
		$('#transactions-title').text(env.find('.envelope-name').text());
	},
	update: function (envelopes) {
		$.each(envelopes, function(i, item){
			var envelope = $('#envelope-tree li[envelope_id="' + item.id + '"]');
			$('div.envelope-name', envelope).text(item.name);
			if (envelope.hasClass('ui-selected')){
				$('#transactions-title').text(item.name);
			}
			if (item.balance !== undefined) {
				$('.envelope-balance', envelope)
					.html(parseFloat(item.balance).toFixed(2))
					.effect('highlight', { color: '#9BFFA3' }, 3000);

				if (item.balance < 0)
					$('.envelope-balance', envelope).addClass('negative');
				else
					$('.envelope-balance', envelope).removeClass('negative');
			}
			if (item.transaction_count !== undefined){
				$('.transaction-count', envelope).text(item.transaction_count);
			}
		});
	} 
};

