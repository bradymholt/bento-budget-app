class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :authenticate_user!
  #before_filter :set_user_time_zone
  layout Proc.new { |controller| controller.request.xhr? || (request.format == :mobile) ? false : nil }
  helper_method :mobile_device?
  helper_method :current_user
  helper_method :current_user_id
  helper_method :user_signed_in?
  helper_method :show_getting_started_nav?
  helper_method :logout

 private
  def protect_against_forgery?
    unless request.format.json?
      super
    end
  end

   def authenticate_user!
    expire_time = session[:expires_at] || Time.now
    session_time_left = (expire_time - Time.now).to_i
    session_expired = (session_time_left <= 0)

    if !user_signed_in? || session_expired?
      if request.format.json?
        render :nothing => true, :status => :unauthorized
      else
        redirect_to signin_url
      end
    else
      session[:expires_at] = 30.minutes.from_now
    end
  end

  def force_subscription!
      unless current_user.is_subscriber?
        redirect_to upgrade_url
      end
  end

  def user_signed_in?
     !session[:user_id].nil?
  end

  def session_expired?
    expire_time = session[:expires_at] || Time.now
    session_time_left = (expire_time - Time.now).to_i
    session_expired = (session_time_left <= 0)
    if session_expired
        flash.notice = "Session expired!"
    end
    session_expired
  end

  def current_user
    @current_user ||= User.where(:id => session[:user_id]).first if session[:user_id]
  end

  def current_user_id
    session[:user_id]
  end

  def mobile_device?
      (request.user_agent =~ /Mobile|webOS/) && (request.user_agent !~ /iPad/)
  end

  def set_user_time_zone
    Time.zone = session[:time_zone] if !session[:time_zone].nil?
  end

  def show_getting_started_nav?
      (current_user.sign_in_count <= 5)
  end

end
