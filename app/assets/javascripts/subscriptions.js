var Subscriptions = {
	checkCount: 0,
	checkMax: 5,
	progress_percent: 0,
	initNew: function(){
		setTimeout(Subscriptions.check, 4000);
		setTimeout(Subscriptions.updateProgress, 1000);
	},
	check: function(){
		Subscriptions.checkCount++;
		$.getJSON("/subscriptions/check", function( data ) {
			if (data.is_subscriber !== undefined && data.is_subscriber === true) {
				$('#subscription_checking').hide();
				$('li.subscriptions_index').hide();
				$('#subscription_confirmation').show();
			} else if (Subscriptions.checkCount <= Subscriptions.checkMax)  {
				setTimeout(Subscriptions.check, 3000);
			} else {
				$('#subscription_checking').hide();
				$('#subscription_failed').show();
			}
		});
	},
	updateProgress: function(){
		Subscriptions.progress_percent += 5;
		$('#progress-bar').css('width', Subscriptions.progress_percent + '%');
		if (Subscriptions.progress_percent < 100){
			setTimeout(Subscriptions.updateProgress, 1000);
		}
	}
};