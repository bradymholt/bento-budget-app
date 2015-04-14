var UserEdit = {
	init: function(){
		Common.init();
		Common.setupCheckboxInputDependency($('#new-transactions-notify'), $('#new-transactions-notify-weeks'));
	}
};

var UserNew = {
	init: function(){
		$('#user_time_zone').val(jstz.determine().name());
	}
}