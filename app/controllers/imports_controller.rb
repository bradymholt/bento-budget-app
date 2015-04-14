class ImportsController < ApplicationController

	layout false

	def index 
		@accounts = Account
			.where(:user_id => current_user_id)
			.where(:active => true)
		if (!@accounts.any? { |a| a.linked? })
			redirect_to new_import_path
		elsif (!@accounts.any? { |a| !a.linked? })
			redirect_to linked_import_imports_path
		else
			render
		end
	end

	def new
		@import = TransactionFileImport.new
		@accounts = Account.where(:user_id => current_user_id).where(:active => true)
	end

	def create
		@import = TransactionFileImport.new(import_params)
		@import.user_id = current_user_id

	    if @import.valid?
	    	accepted_transaction_count = @import.import
	    	@envelopes = Envelope.with_balance(current_user_id).where(:envelope_group_id => EnvelopeGroup::ENVELOPE_GROUPS[:new_transactions])
	    	@data = { :success => { :notice => "#{accepted_transaction_count} transaction(s) imported successfully.", :envelopes => @envelopes, :refresh => :transactions } }
	     	render :success
	    else
	      @accounts = Account.where(:user_id => current_user_id).where(:active => true)
	      render :new, :status => :unprocessable_entity
	    end
	end

	def linked_import
		set_linked_accounts
	end

	def linked_import_start
		set_linked_accounts
		is_error = false

		if !params[:accounts].blank?
			accepted_count_total = 0
			any_errors = false
			@linked_accounts.each do |acct|
				account_parameter = params[:accounts].find{ |a| a[:id] == acct.id.to_s}
				if !account_parameter.nil?
					if !acct.linked_frequency_allowed?
						#set error message for display but do not save b/c this is not a 'true' error
						acct.linked_last_attempt_error = true
			            acct.linked_last_error_message = "Updates allowed only once every #{Account::LINKED_MAX_FREQ_HOURS} hours.  The last update was at #{acct.linked_last_success_date.strftime('%I:%M%p')}."
			  		else
						linked_password = account_parameter[:password].blank? ? acct.linked_password : account_parameter[:password]
						
						begin
							accepted_count_total = accepted_count_total + acct.linked_import_transactions(linked_password)
						rescue Exception => e
							any_errors = true
							Rails.logger.debug e
						end
					end
			
					any_errors = (any_errors || acct.linked_last_attempt_error == true)
				end
			end
			if (any_errors)
				flash.now[:notice] = "Update complete but some errors were encountered.  Details are shown below for each account."
			else
				flash.now[:success] = "Update complete -  #{accepted_count_total} new transaction(s) imported."
			end
		else
			is_error = true
			flash.now[:error] = "No accounts were selected."
		end
		
    	render partial: "linked_accounts", :status => is_error ? :unprocessable_entity : :ok
	end

	private
	def set_linked_accounts
		@linked_accounts = Account.where_linked.where(:user_id => current_user_id)
	end

	def import_params
		params.required(:transaction_file_import).permit(:account_id, :transaction_file)
	end
end