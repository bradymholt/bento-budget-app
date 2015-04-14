class EnvelopesController < ApplicationController
	before_action :set_envelope, only: [:edit, :update, :delete, :destroy]
  before_action :set_groups, only: [:new, :edit]
  respond_to :html, :json, :mobile

  def index
    @envelopes = Envelope.with_balance(current_user_id)
    .joins(:envelope_group)
      .order('envelope_groups.user_id, envelope_groups.sort_index, envelope_groups.name, envelopes.sort_index, envelopes.name')
    .where(envelope_groups: { visible: true })
    
    respond_with(@envelopes)
  end

  def new
    @envelope = Envelope.new
    @envelope.envelope_group_id = params[:group_id]
    respond_with(@envelope)
  end

  def create
     @envelope = Envelope.new(envelope_params)
     @envelope.user_id = current_user_id

    if @envelope.save 
      respond_to do |format|
        format.json { render :json => { :success => { :notice => 'Envelope created successfully.', :refresh => :envelopes } } }
        format.html { redirect_to envelopes_url, notice: 'Envelope created successfully.' }
      end
    else
      set_groups
      respond_with(@envelope, :status => :unprocessable_entity)
    end
  end

  def edit
   respond_with(@envelope)
  end

  def update
     if @envelope.update_attributes(envelope_params)
       respond_to do |format|
         format.json { render :json => { :success => { :notice => 'Envelope successfully updated.', :refresh => :envelopes } } }
         format.html { redirect_to envelopes_url, notice: 'Envelope successfully updated.' }
       end
     else 
      set_groups
      respond_with(@envelope, :status => :unprocessable_entity)
    end
  end

  def delete
    @envelope_groups = EnvelopeGroup.with_envelopes(current_user_id).where.not(envelopes: { id: params[:id] })
    respond_with(@envelope)
  end

  def destroy
    @envelope.assign_attributes(envelope_params)
    if @envelope.destroy
      respond_to do |format|
           format.json { render :json => { :success => { :notice => 'Envelope successfully deleted.', :refresh => :envelopes } } }
           format.html { redirect_to envelopes_url, notice: 'Envelope successfully deleted.' }
         end
    else 
      @envelope_groups = EnvelopeGroup.with_envelopes(current_user_id).where.not(envelopes: { id: params[:id] })
      render :delete, :status => :unprocessable_entity
    end
  end

  def reorder
    params[:order].each do |o|
      envelope = Envelope.find(o[:id])
      envelope.update_attributes(:envelope_group_id => o[:group_id], :sort_index => o[:sort_order])
    end

    render :json => { :success => { :notice => "New envelope order saved." } }
  end

  def funded_amounts
    date_seed = params[:date] ||= DateTime.now
    date_start = date_seed.to_date.strftime("%Y-%m-01").to_date

    @funded = Transaction
      .select('envelope_id, sum(amount) amount')
      .where(:user_id => current_user_id)
      .where('allocation_id IS NOT NULL')
      .where('date >= ? AND date < ?', date_start, date_start + 1.month)
      .group(:envelope_id).collect { |a| { :envelope_id => a.envelope_id, :amount => a.amount } }
    
     render :json => { :month_name => date_start.strftime("%B"), :funded_amounts => @funded } 
  end

  private
  def set_envelope
    @envelope = Envelope.where(:user_id => current_user_id).find(params[:id])
  end

  def set_groups
    @groups = EnvelopeGroup.where(:user_id => current_user_id, :visible => true)
  end

  def envelope_params
    params.require(:envelope).permit(:name, :envelope_group_id, :delete_move_to_envelope_id)
  end
end
