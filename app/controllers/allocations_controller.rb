class AllocationsController < ApplicationController
	before_action :set_allocation, only: [:edit, :update, :delete, :destroy]
	before_action :set_ancillary, only: [:edit, :new]
	respond_to :html, :json

	def new
		source_transactions = []
		@is_new_account_balance = !params[:new_account_balance].blank?
		@is_remove_account_balance = !params[:remove_account_balance].blank?

		if params[:ids].nil?
			source_transactions = Transaction.joins(:envelope_group)
				.where(:user_id => current_user_id)
				.where(envelope_groups: { id: EnvelopeGroup::ENVELOPE_GROUPS[:unallocated_income] } )
		else
			source_transactions = Transaction.find(params[:ids].split(','))
		end

		if source_transactions.any?{ |t| !t.is_associated? }
			source_transactions.reject!{ |t| t.is_associated? }
			@allocation = Allocation.new_with_defaults(source_transactions)
			respond_with(@allocation)
		else
			redirect_to edit_transaction_url(source_transactions.first{ |t| is_associated? })
		end
	end

	def create
		@allocation = Allocation.new(allocation_params)
		affected_envelope_ids = @allocation.all_envelope_ids
		@allocation.user_id = current_user_id

	      if @allocation.save
	      	respond_to do |format|
		        format.json { 
		        	affected_envelope_ids << @allocation.all_envelope_ids
		        	@envelopes = Envelope.with_balance(current_user_id).where(:id => affected_envelope_ids.uniq)
		        	render :json => { :success => { :notice => 'Envelopes successfully funded.', :envelopes => @envelopes, :refresh => :transactions } } 
		        }
		        format.html { redirect_to root_url, notice: 'Envelopes successfully funded.' }
      		end
	      else
	        set_ancillary
			respond_with(@allocation, :status => :unprocessable_entity)
	      end
	end


	def edit 
	end

	def update
		  affected_envelope_ids = @allocation.all_envelope_ids
	      
	      if @allocation.update(allocation_params)
	        respond_to do |format|
		        format.json { 
		        	affected_envelope_ids << @allocation.all_envelope_ids
		        	@envelopes = Envelope.with_balance(current_user_id).where(:id => affected_envelope_ids.uniq)
		        	render :json => { :success => { :notice => 'Envelopes successfully funded.', :envelopes => @envelopes, :refresh => :transactions } } 
		        }
		        format.html { redirect_to root_url, notice: 'Envelopes successfully funded.' }
	  		end
	      else
	      	set_ancillary
			respond_with(@allocation, :status => :unprocessable_entity)
	      end
	end


	def delete
	end

 	def destroy
	  @allocation.destroy
      respond_to do |format|
     	format.json { render :json => { :success => { :notice => 'Allocation successfully undone.', :refresh => [:envelopes, :transactions] } } }
        format.html { redirect_to root_url, notice: 'Allocation successfully undone.' }
      end
  	end

	private
	def set_allocation
		@allocation = Allocation.where(:user_id => current_user_id).find(params[:id])
	end

	def set_ancillary
		@envelopes = Envelope.with_groups(current_user_id).where(envelope_groups: { user_id: current_user_id })
		@unallocated_income_envelope = Envelope.unallocated_income_envelope(current_user_id)
		@allocation_plans = AllocationPlan.where(:user_id => current_user_id)
		
		@balances = Hash[Envelope.with_balance(current_user_id).collect { |b| [b.id, b.balance] }]
		@balances.default = 0
		
		@budgets = Hash[Budget.where(:user_id => current_user_id).collect { |b| [b.envelope_id, b.amount]}]
		@budgets.default = 0
	end

	def allocation_params
		params[:allocation][:envelope_amounts] = ActiveSupport::JSON.decode(params[:allocation][:envelope_amounts])
		params[:allocation][:user_id] = current_user_id
		params[:allocation][:source_transaction_ids] = params[:allocation][:source_transaction_ids].scan(/\d+/) # "[3, 5]" > [3, 5]
		params.required(:allocation).permit(:amount, :date, :name, :user_id, :source_transaction_ids => [], envelope_amounts: [:envelope_id, :amount])
	end
end