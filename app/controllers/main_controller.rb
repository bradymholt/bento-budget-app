class MainController < ApplicationController
  helper_method :show_welcome?
  
  def index
  	respond_to do |format|
          format.html
          format.mobile { redirect_to :controller => :envelopes }
     end
  end

  private 
  def show_welcome?
    (current_user.sign_in_count == 1)
  end
end
