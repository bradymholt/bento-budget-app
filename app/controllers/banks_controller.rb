class BanksController < ApplicationController
  def notes
  	bank = Bank.find(params[:id])
    @notes = bank.notes
    render :json => {:notes => @notes } 
  end
end
