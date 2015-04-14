class FiltersController < ApplicationController
	respond_to :html, :json

	def index
		@user = current_user
		
		if (@user.transaction_filters.size == 0)
			@user.transaction_filters.build
		end

		set_template_and_groups
		
		respond_with(@filters)
	end
	
	def save
		@user = current_user
		respond_to do |format|
		    if @user.update(filter_params)
		    	format.json {
		    		affected_envelope_ids = TransactionFilter.run_filters(current_user_id)
		    		if affected_envelope_ids.size > 0
		    			envelopes = Envelope.with_balance(current_user_id).where(:id => affected_envelope_ids.uniq)
		    			render :json => { :success => { :notice => 'Filters saved and run successfully.', :envelopes => envelopes, :refresh => :transactions } } 
		    		else
		    			render :json => { :success => { :notice => 'Filters saved successfully.' } }
		    		end
		    	}
		    	format.html { redirect_to root_url, notice: 'Filters saved successfully.' }
		    else
		    	set_template_and_groups
		    	@errors = @user.transaction_filters.collect{ |f| f.errors.full_messages }.flatten.uniq
		    	format.html { render action: 'index', :status => :unprocessable_entity }
		    end
	    end
	end

	private
	def set_template_and_groups
		@user.transaction_filters.build({ :is_template => true }) #template
		
		#preload envelopes to prevent round trips to db
		ActiveRecord::Associations::Preloader.new(
 			 @user, [ transaction_filters: :envelope, transaction_filters: { :envelope => :envelope_group } ]
		).run()

		@envelope_groups = EnvelopeGroup.with_envelopes(current_user_id)
	end

	def filter_params
		params.required(:user).permit(:transaction_filters_attributes => [ :search_text, :amount, :envelope_id, :id, :_destroy, :is_template ])
	end
end
