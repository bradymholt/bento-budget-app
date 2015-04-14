class TransfersController < ApplicationController
	before_action :set_transfer, only: [:edit, :update, :delete, :destroy]
	before_action :set_envelope_groups, only: [:new, :edit]
	respond_to :html, :json

	def new
		@transfer = Transfer.new_with_defaults
		respond_with(@transfer)
	end

	def create
		@transfer = Transfer.new(transfer_params)
		@transfer.user_id = current_user_id

		if @transfer.save
		  respond_to do |format|
	        format.json { 
	        	@envelopes = Envelope.with_balance(current_user_id).where(:id => [@transfer.from_envelope_id, @transfer.to_envelope_id])
	        	render :json => { :success => { :notice => 'Transfer completed.', :envelopes => @envelopes, :refresh => :transactions } } 
	        }
	        format.html { redirect_to envelopes_url, notice: 'Transfer completed.' }
	      end
		else
			set_envelope_groups
			respond_with(@transfer, :status => :unprocessable_entity)
    	end
	end

	def edit 
	end

	def update
	      if @transfer.update(transfer_params)
	        respond_to do |format|
		      format.json { 
		      	@envelopes = Envelope.with_balance(current_user_id).where(:id => [@transfer.from_envelope_id, @transfer.to_envelope_id])
		      	render :json => { :success => { :notice => 'Transfer updated.', :envelopes => @envelopes, :refresh => :transactions } } 
		      }
		      format.html { redirect_to envelopes_url, notice: 'Transfer updated.' }
		     end
	      else
	      	set_envelope_groups
	        respond_with(@transfer, :status => :unprocessable_entity)
    	end
	end

	def delete
    end

    def destroy
	  @transfer.destroy
      respond_to do |format|
     	format.json { render :json => { :success => { :notice => 'Transfer successfully deleted.', :refresh => [:envelopes, :transactions] } } }
        format.html { redirect_to root_url, notice: 'Transfer successfully deleted.' }
      end
  	end

	private
	def set_transfer
		@transfer = Transfer.where(:user_id => current_user_id).find(params[:id])
	end

	def set_envelope_groups
		@envelope_groups = EnvelopeGroup.with_envelopes(current_user_id)
		.where.not(envelope_groups: { id: EnvelopeGroup::ENVELOPE_GROUPS[:new_transactions] })
	end

	def transfer_params
		params.required(:transfer).permit(:amount, :date, :from_envelope_id, :to_envelope_id, :notes)
	end
end