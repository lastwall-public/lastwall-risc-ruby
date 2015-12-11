require 'rubygems'
require 'json'
require 'net/http'
require 'securerandom'
require 'base64'
require 'openssl'
require './RiscResponse.rb'
require "erb"

include ERB::Util

class Risc

	@token = ""
	@secret = ""
	@http_basic_auth = true
	@get_params_in_url = true
	@api_url = ""
	@initialized = false

	def initialize(api_key="LWK750D380544E303C57E57033CFCE7835F5FDFEE3DE404F4AA4D7D5397D5D35010", api_secret="4B60355A24C907DEBF32B451B87B8794C7F9B8BE1D70D2488C36CAF85E37DB2C", http_basic_auth = true, api_url = "https://risc.lastwall.com/")
	#def initialize(api_key, api_secret, http_basic_auth = true, api_url = "https://risc.lastwall.com/")
		@token = api_key
		@secret = api_secret
		@http_basic_auth = http_basic_auth
		@api_url = api_url
		@initialized = true

		if !(@api_url.end_with? "/")
			@api_url+"/"
		end
	end

	#
	# Verify your API key.
	#
	# @return RiscResponse the server response
	#
	def Verify()
		return CallAPI("GET", @api_url+"verify")
	end

	#
	# Get the base URL for the RISC javascript. This url must be postfixed with a username.
	#
	# @return string The base script URL.
	#
	def GetScriptUrl
		return @api_url + 'risc/script/' + @token
	end

	# /**
	#  * Decrypts an encrypted RISC snapshot and returns the decrypted result.
	#  *
	#  * @param string $enc_snapshot    The encrypted snapshot object, which should be a JSON string returned from the Lastwall RISC server
	#  *
	#  * @return object The decrypted snapshot result. The return object should contain the following values:
	#  * string   snapshot_id
	#  * string   browser_id
	#  * date     date
	#  * number   score
	#  * string   status
	#  * boolean  passed
	#  * boolean  risky
	#  * boolean  failed
	#  */
	def DecryptSnapshot(enc_snapshot)
		obj = JSON.parse(enc_snapshot)
		password = (@secret + @secret)[obj["ix"],32]
		key = [password].pack("H*")
		iv = [obj["iv"]].pack("H*")
		data = Base64.decode64(obj["data"])

		alg = "AES-128-CBC"
		decode_cipher = OpenSSL::Cipher::Cipher.new(alg)
		decode_cipher.decrypt
		decode_cipher.key = key
		decode_cipher.iv = iv
		msg = decode_cipher.update(data)
		msg << decode_cipher.final()

		ret = JSON.parse(msg)
		ret["passed"] = (ret["status"] == "passed")
		ret["risky"] = (ret["status"] == "risky")
		ret["failed"] = (ret["status"] == "failed")

		return ret
	end

	# /**
	#  * Call the Validate API to ensure the integrity of the encrypted RISC result.
	#  *
	#  * @param object $snapshot    The snapshot object, as decrypted by the DecryptSnapshot() function
	#  *
	#  * @return RiscResponse the server response
	#  */
	def ValidateSnapshot(snapshot)
		data = {
			:snapshot_id => snapshot["snapshot_id"],
			:browser_id => snapshot["browser_id"],
			:date => snapshot["date"],
			:score => snapshot["score"],
			:status => snapshot["status"]
		}
		return CallAPI("POST", @api_url + "api/validate", data)
	end

	def CallAPI(method, url, data = false)

		full_url = url
		req = Net::HTTP::Get.new(full_url)

		# puts "Full Url: "+full_url
		# puts "Params in URL: "+ (@get_params_in_url?"true":"false")
		# puts "Method: " + method
		# puts "Basic Auth: "+(@http_basic_auth?"true":"false")


		# Set the request parameters, either in the URL or in the body
		if (@get_params_in_url && method == "GET")
			if (data)
				full_url = url + URI.encode_www_form(data)
				req = Net::HTTP::Get.new(full_url)
			else
				#setup for post
				req = Net::HTTP::Post.new(full_url)
				req.set_form_data(data)
			end
		end

		# Determine authorization type
		if (@http_basic_auth)
			req.basic_auth(@token,@secret)
		else
			#set digest authentication headers
			timestamp = Time.now.to_i
			request_id = CreateGuid()
			hash_str = full_url + request_id + timestamp
			digest = OpenSSL::Digest.new('sha1')
			hmac = OpenSSL::HMAC.digest(digest, @secret, hash_str)
			signature = Base64.encode64(hmac)

			req["Content-Type"] = "application/x-www-form-urlencoded"
			req["X-Lastwall-Token"] = @token
			req["X-Lastwall-Timestamp"] = timestamp
			req["X-Lastwall-Request-Id"] = request_id
			req["X-Lastwall-Signature"] = signature
		end

		uri = URI(full_url)
		http = Net::HTTP.new(uri.host,uri.port)
		http.use_ssl = (uri.scheme == "https")

		# puts @api_url
		# puts http.inspect
		# puts req.inspect

		res = http.request(req)

		return RiscResponse.new(res.code, res.body)

	end

	def CreateGuid()
		return SecureRandom.uuid
	end

end
