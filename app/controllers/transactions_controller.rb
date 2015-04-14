class TransactionsController < ApplicationController
	before_action :set_transaction, only: [:edit, :update, :delete, :destroy]
	respond_to :html, :json, :mobile

	def index
		@envelope_column_visible = false
		@account_column_visible = false
		@days_limit = params[:days]
		@is_unallocated_income_envelope = false
		ending_balance = 0

		@transactions = Transaction
			.where(:user_id => current_user_id)
			.where((!@days_limit.nil? ? "date >= ?" : ""), Date.today - @days_limit.to_i) 

		if !params[:envelope_id].nil?
			envelope = Envelope.with_balance(current_user_id).where(:id => params[:envelope_id]).first()
			ending_balance = envelope.balance
			@is_unallocated_income_envelope = (envelope.envelope_group_id == EnvelopeGroup::ENVELOPE_GROUPS[:unallocated_income])
			@transactions = @transactions.where(:envelope_id => params[:envelope_id]).includes(:account)
			@account_column_visible = true
		else
			ending_balance = Account.with_balance(current_user_id).where(:id => params[:account_id]).first().balance
			@transactions = @transactions.where(:account_id => params[:account_id]).includes(:envelope)	
			@envelope_column_visible = true
		end

		respond_to do |format|
			format.html {
				@transactions = Transaction.apply_rolling_balance(@transactions, ending_balance)
			}
			format.mobile
			format.json { render json: @transactions }
		end
	end

	def new
		@transaction = Transaction.new_with_defaults(current_user_id) 
		set_envelope_groups
		set_accounts
		respond_with(@transaction)
	end

	def create
		 @transaction = Transaction.new_with_defaults(current_user_id)
		 @transaction.attributes = transaction_params
    
	    if @transaction.save 
	      respond_to do |format|
		    @envelopes = Envelope.with_balance(current_user_id).where(:id => @transaction.envelope_amounts.map{ |e| e[:envelope_id] })
	        format.json { render :json => { :success => { :notice => 'Transaction created successfully.', :envelopes => @envelopes, :refresh => [:transactions, :accounts] } } }
	        format.html { redirect_to transaction_url, notice: 'Transaction created successfully.' }
	      end
	    else
	      set_envelope_groups
	      set_accounts
	      respond_with(@transaction, :status => :unprocessable_entity)
	    end
	end
	
	def edit
	  if (@transaction.is_split_child?)
	  	redirect_to edit_transaction_url(@transaction.parent) 
	  elsif (@transaction.is_allocation?)
	  	redirect_to edit_allocation_url(@transaction.allocation_id)
	  elsif (@transaction.is_transfer?)
	  	redirect_to edit_transfer_url(@transaction.transfer_id)
	  else
	  	set_envelope_groups
		respond_with(@transaction)
	  end
	end

	def update
		affected_envelope_ids = @transaction.envelope_amounts.map{ |e| e[:envelope_id] }
		original_envelope_id = @transaction.envelope_id
		@transaction.user_id = current_user_id
		if @transaction.update(transaction_params)
			respond_to do |format|
	        	format.json { 
	        		affected_envelope_ids << @transaction.envelope_amounts.map{ |e| e[:envelope_id] }
		        	@envelopes = Envelope.with_balance(current_user_id).where(:id => affected_envelope_ids.uniq)
		        	render :json => { :success => { :notice => 'Transaction successfully saved.', :envelopes => @envelopes, :refresh => :transactions } } 
		        }
		        format.html { redirect_to root_url, notice: 'Transaction successfully saved.' }
		        format.mobile  { redirect_to envelope_transactions_path(original_envelope_id, :format => :mobile) }
		    end
	     else
	      	set_envelope_groups
			respond_with(@transaction, :status => :unprocessable_entity)
	     end
	end

 	def delete
    end

    def destroy
	  @transaction.destroy
      respond_to do |format|
     	format.json { render :json => { :success => { :notice => 'Transaction successfully deleted.', :refresh => [:envelopes, :transactions, :accounts] } } }
        format.html { redirect_to root_url, notice: 'Transaction successfully deleted.' }
      end
  	end

	def assign
		affected_envelope_ids = [params[:envelope_id]]
		trans = Transaction.find(params[:id])
		trans.each do |t|
			affected_envelope_ids << t.envelope_id
			t.envelope_id = params[:envelope_id]
			t.save
		end

		affected_envelopes = Envelope.with_balance(current_user_id).where(:id => affected_envelope_ids)
		render :json => { :success => { :notice => "Transactions successfully assigned.", :envelopes => affected_envelopes } }
	end

	private
	def set_accounts
		 @accounts = Account.where(:user_id => current_user_id).where(:active => true)
	end

	def set_transaction
		@transaction = Transaction.where(:user_id => current_user_id).find(params[:id])
	end

	def set_envelope_groups
		@envelope_groups = EnvelopeGroup.with_envelopes(current_user_id)
	end

	def transaction_params
		if !params[:transaction][:envelope_amounts].nil?
			params[:transaction][:envelope_amounts] = ActiveSupport::JSON.decode(params[:transaction][:envelope_amounts])
		end
		params.required(:transaction).permit(:name, :date,  :account_id, :amount, :envelope_id, :notes, :transaction_type, envelope_amounts: [:envelope_id, :notes, :amount])
	end
end
