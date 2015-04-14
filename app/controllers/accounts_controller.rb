class AccountsController < ApplicationController
  before_action :set_account, only: [:edit, :update, :convert_to_linked, :delete, :destroy]
  before_action :set_banks, only: [:new_linked, :convert_to_linked, :edit]
  before_action :set_types, only: [:edit, :convert_to_linked, :new]
  respond_to :html, :json, :mobile

 	def index
   		@accounts = Account.with_balance(current_user_id).where(:active => true)
    	respond_with(@accounts)
  end

 	def new
    respond_with(@account = Account.new)
	end

  def new_linked
    respond_with(@account = Account.new)
  end

  def convert_to_linked
  end

  def create
  	@account = Account.new(account_params)
    @account.user_id = current_user_id
  	
    if @account.save 
       respond_to do |format|
          format.json { 
              data = { :success => { :notice => 'Account successfully created.', :refresh => [:accounts, :envelopes] } }
              if !@account.initial_transaction.envelope.is_hidden_envelope?
                data[:success][:navigate] = { :modal => true, :title => 'Allocate New Account Balance', :button_text => 'Allocate', :href => new_allocation_path(:ids => @account.initial_transaction_id, :new_account_balance => "1"  ) }
              end
              render :json => data
          }
          format.html { redirect_to accounts_url, notice: 'Account successfully created.' }
       end
    else
      set_types
      respond_to do |format|
          format.html {
            if (!params[:is_linked].blank?)
              set_banks
              render :new_linked, :status => :unprocessable_entity
            else 
              render :new, :status => :unprocessable_entity
            end
          }
       end
    end
  end
  
  def edit
    respond_with(@account)
  end

  def update
      if @account.update_attributes(account_params)
        respond_to do |format|
          format.json { render :json => { :success => { :notice => 'Account successfully updated.', :refresh => :accounts } } }
          format.html { redirect_to accounts_url, notice: 'Account successfully updated.' }
         end
      else 
          set_banks
          set_types
          respond_with(@account, :status => :unprocessable_entity)
      end
  end

  def delete
  end

  def destroy
    offset_transaction = nil

    if params[:inactivate] == "true"
      offset_transaction = @account.inactivate
    else 
      @account.destroy
    end

    respond_to do |format|
         format.json { 
              data = { :success => { :notice => 'Account successfully removed.', :refresh => [:accounts, :envelopes, :transactions] } }
              if !offset_transaction.nil?
                data[:success][:navigate] = { :modal => true, :title => 'Allocate Account Removal Balance', :button_text => 'Allocate', :href => new_allocation_path(:ids => offset_transaction.id, :remove_account_balance => "1" ) }
              end
              render :json => data
          }
         format.html { redirect_to accounts_url, notice: 'Account successfully removed.' }
    end
  end

  def linked_bank_accounts
    bank = Bank.find(params[:account_bank_id])

    open_bank_proxy = OpenBankProxy.new_with_bank(bank)
    open_bank_proxy.user_id = params[:user_id]
    open_bank_proxy.password = params[:password]
    open_bank_proxy.security_answers = params[:security_answers]
    open_bank_response = open_bank_proxy.fetch_accounts

    render :json => open_bank_response.response, :status => open_bank_response.status
  end

  def linked_bank_balance
    bank = Bank.find(params[:account_bank_id])

    open_bank_proxy = OpenBankProxy.new_with_bank(bank)
    open_bank_proxy.user_id = params[:user_id]
    open_bank_proxy.password = params[:password]
    open_bank_response = open_bank_proxy.fetch_statement(params[:bank_id], params[:account_id], params[:account_type], DateTime.now - 1.month)

    if !open_bank_response.is_error?
      data = { :balance => open_bank_response.statement[:ledger_balance][:amount], :balance_date => open_bank_response.statement[:ledger_balance][:date].to_date.strftime('%Y-%m-%d'), :balance_transaction_ids => [] }
      data[:balance_transaction_ids] = open_bank_response.statement[:transactions].collect{ |t| t[:id] }
    else
      data = open_bank_response.response
    end

    render :json => data, :status => open_bank_response.status

  end

  private
  def set_account
     @account = Account.where(:user_id => current_user_id).find(params[:id])
  end

  def set_types
     @types = AccountType.all
  end

  def set_banks
    @banks = Bank.where(:active => true)
  
    @grouped_banks = [
      ['All Banks',
         @banks.map { |bank| [bank.name, bank.id, :notes => !bank.notes.blank?, :ofx => (bank.auto_import_method_id == AutoImportMethod::IMPORT_METHODS[:ofx]) ] }]
    ]
 
    @banks_featured = @banks.select { |bank| bank.featured == true }
    @banks_featured = @banks_featured.sort { |x,y| x.name <=> y.name }

    if @banks_featured.length > 0
      @grouped_banks.unshift(
        ['Popular Banks', 
          @banks_featured.map { |bank| [bank.name, bank.id, :notes => !bank.notes.blank?, :ofx => (bank.auto_import_method_id == AutoImportMethod::IMPORT_METHODS[:ofx]) ] }]
      )
    end
  end

   def account_params
    params.require(:account).permit(:name, :bank_id, :initial_balance_amount, :initial_balance_date, :account_type, :linked_account_number, :linked_bank_code, :linked_user_id, :linked_password, :linked_initial_balance_bank_transaction_ids, :linked_password_new, :linked_security_answers)
  end
 end
  