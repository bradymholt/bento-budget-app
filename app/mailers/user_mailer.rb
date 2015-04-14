class UserMailer < ActionMailer::Base

  def signup_confirmation(user)
  	 @user = user
		 mail(:to => user.email, :subject => "Welcome to Bento Budget!")
  end
  
  def new_transactions(user, transactions)
    @user = user
    @transactions = transactions
		mail(:to => user.email, :subject => "#{transactions.size} New Transactions")
  end

  def email_change(user, old_email)
    @user = user
    @new_email = user.email
    @old_email = old_email
    mail(:to => @old_email, :cc => user.email, :subject => "Email Address Changed")
  end

  def new_subscription(user, is_trial_period)
    @user = user
    @is_trial_period = is_trial_period
    mail(:to => user.email, :subject => "Your Account Has Been Upgraded!")
  end

  def subscription_cancelled(user, cancel_reason)
    @user = user
    @reason = cancel_reason
    mail(:to => user.email, :subject => "Subscription Cancelled")
  end

  def password_reset(user)
    @user = user
    mail :to => user.email, :subject => "Password Reset"
  end
end
