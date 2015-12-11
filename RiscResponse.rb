require 'rubygems'
require 'json'

class RiscResponse

	@response
	@body
	@code
	@error

	def initialize(status_code, response)
		if response.nil?
			@error = "No response from server"
			return
		end

		@response = response
		@code = status_code.to_i()
		@body = JSON.parse(response)

		if @body.has_key? "status"
			if @body["status"] == "Error"
				@error = @body["error"]
			end
		elsif @body.has_key? "error"
			@error = @body["error"]
		elsif status_code < 200 || status_code >= 400
			@error = response
		end
	end

	#
	# Check whether the API request was successful.
	#
	# @return boolean False if any error occurred.
	#/
	 def OK()
	 	return @code >= 200 || @code < 400
	 end	

	#
	# Get the HTTP status code of the request.
	#
	# @return integer The HTTP status code, or 0 if the server didn't respond.
	#
	def Code()
		return @code
	end

	#
	# Get the status of the Lastwall Risc request.
	#
	# @return string 'Error' if there was an error, otherwise returns the status of the request (typically 'OK', but can also be a session status).
	#
	def Status()
		if @body.has_key? "status"
			return @body["status"]
		elsif (@code>=200 || @code<400)
			return "OK"
		end
		return "Error"
	end

	#
	# Get the specific error message.
	#
	# @return string The specific error message, or an empty string if there was no error.
	#
	def Error()
		return @error
	end

	#
	# Get the message response as an object, ie. the JSON-decoded message body.
	#
	# @return object The message body, converted from JSON to an object.
	#
	def Body()
		return @body
	end

	#
	# Get the raw response text of the HTTP request.
	#
	# @return string The unparsed response body text.
	#
	def RawResponse()
		return @response
	end

	#
	# Get a specific value from the response object.
	#
	# @param string $key The name of the key
	#
	# @return object The value of the response for that key, or null if the key is not defined.
	#
	def Get(key)
		if @body.has_key? key
			return @body[key]
		end
		return nil
	end
end