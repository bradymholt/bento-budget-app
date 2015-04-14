class EnvelopeGroupsController < ApplicationController
  before_action :set_group, only: [:edit, :update, :delete, :destroy]
	respond_to :html, :json

  def new
    respond_with(@group = EnvelopeGroup.new)
  end

  def create
     @group = EnvelopeGroup.new(envelope_group_params)
     @group.user_id = current_user_id

    if @group.save 
      respond_to do |format|
        format.json { render :json => { :success => { :notice => 'Group created successfully.', :refresh => :envelopes } } }
        format.html { redirect_to envelopes_url, notice: 'Group created successfully.' }
      end
    else
      respond_with(@group, :status => :unprocessable_entity)
    end
  end

	def edit
   respond_with(@group)
  end

   def update
    if @group.update_attributes(envelope_group_params)
      respond_to do |format|
        format.json { render :json => { :success => { :notice => 'Group successfully updated.', :refresh => :envelopes } } }
        format.html { redirect_to root_url, notice: 'Group successfully updated.' }
       end
    else 
       respond_with(@group, :status => :unprocessable_entity)
    end
  end

   def delete
    @assign_to_groups = EnvelopeGroup.where(:user_id => current_user_id, :visible => true).where('id != ?', params[:id])
    respond_with(@group)
  end

  def destroy
    @group.assign_attributes(envelope_group_params)
    if @group.destroy
      respond_to do |format|
           format.json { render :json => { :success => { :notice => 'Group successfully deleted.', :refresh => :envelopes } } }
           format.html { redirect_to envelopes_url, notice: 'Group successfully deleted.' }
         end
    else 
      @assign_to_groups = EnvelopeGroup.where(:user_id => current_user_id, :visible => true).where('id != ?', params[:id])
      render :delete, :status => :unprocessable_entity
    end
  end

  def reorder
    params[:order].each do |o|
      if (!o[:id].blank?)
        group = EnvelopeGroup.find(o[:id])
        group.update_attributes(:sort_index => o[:sort_order])
      end
    end

    render :json => { :success => { :notice => "New Group order saved." } }
  end

  private
  def set_group
    @group = EnvelopeGroup.where(:user_id => current_user_id, :visible => true).find(params[:id])
  end

  def envelope_group_params
    params.require(:envelope_group).permit(:name, :delete_move_to_group_id, :first_envelope_name)
  end
end