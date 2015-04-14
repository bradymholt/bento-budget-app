class OpenBankResponse
	attr_accessor :status, :response, :is_error, :is_security_question_asked

	def is_error?
		is_error || false
	end

	def is_security_question_asked?
		response[:is_security_question_asked]
	end

	def statement
		response[:statement]
	end

	def accounts
		response[:accounts]
	end

	def detailed_error
		response[:detailed_error]
	end

	def friendly_error
		response[:friendly_error]
	end

	def is_bad_request?
		!status.nil? && status.to_s.start_with?("4")
	end
end