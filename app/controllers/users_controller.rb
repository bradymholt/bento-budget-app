 class UsersController < ApplicationController
   before_action :set_user, only: [:edit, :update, :delete, :destroy, :upgrade]
   skip_before_filter :authenticate_user!, :only => [:create, :new]
   respond_to :html

   def edit
   end

   def update
    if @user.update_attributes(user_params)
       respond_to do |format|
        flash.now[:success] = "Settings were successfully saved."
       
        unless @user.time_zone.nil?
          session[:time_zone] = @user.time_zone
        end
         
         format.html { render :edit }
       end
     else 
      respond_with(@user, :status => :unprocessable_entity)
    end
   end

   def new
      @user = User.new
      render :new, :layout => 'sessions'
    end

    def create
      @user = User.new(user_params)
      if @user.save
        UserMailer.signup_confirmation(@user).deliver
        @user.log_signin
        session[:user_id] = @user.id
        session[:expires_at] = 30.minutes.from_now
        unless @user.time_zone.nil?
          session[:time_zone] = @user.time_zone
        end
        redirect_to root_url(:anchor => 'welcome')
      else
        render :new, :layout => 'sessions'
      end
    end

    def upgrade
    end

    def delete
    end

     def destroy
      @user.assign_attributes(user_params)
      if @user.destroy
        reset_session
        redirect_to root_url, :notice => "Account deleted!"
      else 
        render :delete, :status => :unprocessable_entity
      end
    end

    private
    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation, :new_transaction_count_notify, :time_zone)
    end

    def set_user
      @user = User.find(current_user_id)
    end
end