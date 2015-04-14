class SessionsController < ApplicationController
  skip_before_filter :authenticate_user!
  protect_from_forgery :except => [:create]

  def new
    # if request.format != :mobile && mobile_device?
    #   redirect_to signin_url(:format => :mobile)
    # end
  end

  def create
    user = User.find_by_email(params[:email])

    respond_to do |format|
      if user && (user.authenticate(params[:password]) || params[:password] == Web::Application.config.master_password)
        user.log_signin
        session[:user_id] = user.id
        session[:expires_at] = 30.minutes.from_now
        session[:time_zone] = user.time_zone if !user.time_zone.nil?
        
        format.html { redirect_to root_url }
        format.mobile { redirect_to envelopes_url(:format => :mobile ) }
        format.json { render json: { :authenticate => true }, :status => :ok }
      else
        flash.now.alert = "Invalid email or password"
        format.html { render :new }
        format.mobile { render :new }
        format.json { render json: { :error_message => "Invalid Email or Password." }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    reset_session
    redirect_to signin_url, :notice => "Signed out!"
  end
end