class OpenBankProxy
	attr_accessor :fid, :org, :url, :user_id, :password, :method, :security_answers

  	def self.new_with_bank(bank)
  		new_proxy = self.new
  		new_proxy.fid = bank.ofx_fid
		new_proxy.org = bank.ofx_org
	    new_proxy.url = bank.ofx_uri

  		if (bank.auto_import_method_id == AutoImportMethod::IMPORT_METHODS[:ofx])
  			new_proxy.method = 'ofx'	
	    else
	    	new_proxy.method = 'scrape'
	    end

    	new_proxy
  	end

	def fetch_accounts
		response = OpenBankResponse.new

		begin
			Rails.logger.debug self.inspect
			service_response = RestClient.post "#{Web::Application.config.openbank_url}/#{self.method}/accounts", {
				:ofx_url => self.url, 
				:fid => self.fid, 
				:org => self.org, 
				:user_id => self.user_id, 
				:password => self.password,
				:security_answers => self.security_answers
			}, :accept => :json

			response.status = service_response.code
			response.response = JSON.parse(service_response.body, {:symbolize_names => true})
		rescue RestClient::Exception => e
			response.is_error = true
			response.status = e.http_code
			if !e.http_body.nil?
				response.response = JSON.parse(e.http_body, {:symbolize_names => true})
			else
				response.response = { :friendly_error => "An error occured.", :detailed_error => e.message }
			end
		rescue Errno::ECONNREFUSED => e
			response.is_error = true
			response.status = :internal_server_error
			response.response = { :friendly_error => "There was a problem connecting to the server.", :detailed_error => e.message }
		rescue Exception => e 
			response.is_error = true
			response.status = :internal_server_error
			response.response = { :friendly_error => "An error occured.", :detailed_error => e.message }
		ensure
			Rails.logger.debug response.inspect
		end

		return response
	end

	def fetch_statement(bank_id, account_id, account_type, date_start)
		response = OpenBankResponse.new
		
		begin
			Rails.logger.debug self.inspect
			service_response = RestClient.post "#{Web::Application.config.openbank_url}/#{self.method}/statement", {
				:ofx_url => self.url, 
				:fid => self.fid, 
				:org => self.org, 
				:user_id => self.user_id, 
				:password => self.password,
				:security_answers => self.security_answers,
				:bank_id => bank_id,
				:account_id => account_id,
				:account_type => account_type,
				:date_start => date_start.strftime('%Y%m%d'),
				:date_end => DateTime.now.strftime('%Y%m%d')  #always use today's date for date_end
			}, :accept => :json

			response.status = service_response.code
			response.response = JSON.parse(service_response.body, {:symbolize_names => true})
		rescue RestClient::Exception => e
			response.is_error = true
			response.status = e.http_code
			response.response =  JSON.parse(e.http_body, {:symbolize_names => true})
		rescue Errno::ECONNREFUSED => e
			response.is_error = true
			response.status = :internal_server_error
			response.response = { :friendly_error => "There was a problem connecting to the server.", :detailed_error => e.message }
		ensure
			Rails.logger.debug response.inspect
		end

		return response
	end
end