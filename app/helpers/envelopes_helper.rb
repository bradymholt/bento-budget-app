module EnvelopesHelper
 def envelopes_balances(envelopes)
	 last_envelope_group_id = nil
	 ret = "<ul id='envelope-tree'>"

	 envelopes.each do |env|
		if (env.envelope_group_id != last_envelope_group_id)
			if (!last_envelope_group_id.nil?)
				ret += "</ul></li>"
			end 

			if (!env.is_new_transactions_envelope? && !env.is_unallocated_income_envelope?)
				ret += "<li class='group' group_id='" + env.envelope_group_id.to_s() + "'><div class='group-name'>" + env.envelope_group.name + "</div>"
			end 

			ret += "<ul class='group-envelopes'>"
		end
		
		ret += "<li class='envelope" + (env.is_new_transactions_envelope? ? " global new-transactions" : (env.is_unallocated_income_envelope? ? " global unallocated-income" : "")) + "' envelope_id='" + env.id.to_s + "'>"
		
		if (!env.is_new_transactions_envelope?)
			ret += "<div class='envelope-balance adjacent-right"
			
			if (env.balance < 0)
				ret += " negative"
			end
		
			ret += "'>" + number_with_precision(env.balance, :precision => 2, :delimiter => ',') + "</div>"
		else
			ret += "<div class='transaction-count adjacent-right'>"
			ret += env.transaction_count.to_s
			ret += '</div>'
		end
		
		ret += "<div class='envelope-name adjacent-left'>" + env.name + "</div>"
		ret += "</li>"
		
		last_envelope_group_id = env.envelope_group_id
	end
	
	ret += "</ul>"
	return raw ret
	
	end	

	def envelope_options(envelope_groups, selected_id)
		body = ''
		body << options_from_collection_for_select(envelope_groups.reject{ |g| !g.user_id.nil? }.map{ |g| g.envelopes }.flatten, :id, :name, selected_id)
		body << option_groups_from_collection_for_select(envelope_groups.reject{ |g| g.user_id.nil? }, :envelopes, :name, :id, :name, selected_id)
		body.html_safe
	end
end