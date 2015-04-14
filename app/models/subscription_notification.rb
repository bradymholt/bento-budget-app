class SubscriptionNotification < ActiveRecord::Base
	serialize :params
	belongs_to :user
	after_create :handle_notification

	def handle_notification
		cancel_reason = ""

		case transaction_type
			when "subscr_signup"
				#Subscription started
				user.is_subscriber = true
			when "subscr_cancel"
				#Subscription canceled; sent immediately upon cancel.
				user.is_subscriber = false
				cancel_reason = "Subscription cancelled"
			when "subscr_failed"  				
				#Subscription payment failed
				user.is_subscriber = false
				cancel_reason = "Subscription payment failed"
			when "subscr_payment"
				#Subscription payment received
				#check payment_status!
				user.is_subscriber = true
			when "subscr_eot"
				#Subscription expired; paid-through period has passed.
				user.is_subscriber = false
				cancel_reason = "End of subscription"
			when "recurring_payment_suspended_due_to_max_failed_payment"
				user.is_subscriber = false
				cancel_reason = "Subscription payment failed"
		end

	    if user.is_subscriber_changed?
	      if user.is_subscriber
	        UserMailer.new_subscription(user, !user.is_trial_period_used).deliver
	      else
	        UserMailer.subscription_cancelled(user, cancel_reason).deliver
	      end
	    end

	    user.save
    end
end
