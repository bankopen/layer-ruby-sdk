require 'rubygems'
require 'openssl'
require 'base64'
require 'securerandom'
require 'faraday'
require 'json'

#Custom configuration ror_layerpayment
$BASE_URL_SANDBOX = 'https://sandbox-icp-api.bankopen.co'
$BASE_URL_UAT = 'https://icp-api.bankopen.co'
$remote_script='https://sandbox-payments.open.money/layer'
$accesskey='ab484150-c760-11ea-8e37-372cadc23aea'
$secretkey='ecee6e0aae6143214546c2425c3f03141271adc5'
$environment='test'
$sampledata = {
			"amount" => "10.00",
			"currency"=> "INR",
			"name"	  =>"John Doe",
			"email_id" => "john.doe@dummydomain.com",
			"contact_number" => "9831111111",
			"mtx" => "",
			"udf" => ""
			}
  
$error = ''

class TestController < ApplicationController
	
	protect_from_forgery with: :null_session
	
	def index
 		$sampledata['mtx']=SecureRandom.urlsafe_base64(12)
		$error = ""
		@layer_payment_token_data = create_payment_token($sampledata,$accesskey,$secretkey,$environment)  				
		
		if @layer_payment_token_data.key?("error") 
			if @layer_payment_token_data.key?("error_data") 
				@layer_payment_token_data["error_data"].each_value { |val| $error = "#{val}" }			
			else	
				$error = @layer_payment_token_data["error"]
			end 
		end
		
		if $error.length == 0 and @layer_payment_token_data["id"].length < 1 
			$error="E55 Payment error. Token data empty."
		end
		
		if $error.length == 0 and @layer_payment_token_data["id"].length > 0 
		
			@payment_token_data = get_payment_token(@layer_payment_token_data["id"],$accesskey,$secretkey,$environment)
			
			if @payment_token_data.key?("error") 
				if @payment_token_data.key?("error_data") 
					@payment_token_data["error_data"].each_value { |val| $error = "#{val}" }			
				else	
					$error = @payment_token_data["error"]
				end 
			end			
		end
		
		if $error.length == 0 and @payment_token_data["id"].length < 1 
			$error="Payment error. Layer token ID cannot be empty."
		end 
		
		if $error.length == 0 and @payment_token_data["id"].length > 0 and @payment_token_data["status"]=="paid" 
			$error="Layer: this order has already been paid."
		end

		if $error.length == 0 and format("%.2f",@payment_token_data["amount"].to_f) != format("%.2f",$sampledata["amount"].to_f) 
			$error="Layer: an amount mismatch occurred."
		end	
		
		@postvals={}
		@hash=""		
		@token_id=""
		
		if $error.length == 0 
			@postvals = {
				"amount" => @payment_token_data["amount"],
				"id" => @payment_token_data["id"],
				"mtx" => $sampledata["mtx"]
				}
			@hash = create_hash(@postvals,$accesskey,$secretkey)							
			@token_id=@payment_token_data["id"]
		end 		
  	end  	
  
  	def callback 	#response
  		@status=""
  		if params["layer_payment_id"].length == 0
			$error = "Transaction cancelled... Invalid payment id"
  		end
		if $error.length == 0
			@postvals = {
				"amount" => params["layer_order_amount"],
				"id" => params["layer_pay_token_id"],
				"mtx" => params["tranid"]
				}			
			if !verify_hash(@postvals,params["hash"],$accesskey,$secretkey)
				$error="Invalid payment response...Hash mismatch"
			end
		end
		
		if $error.length == 0
			@payment_data = get_payment_details(params["layer_payment_id"],$accesskey,$secretkey,$environment)
			if @payment_data.key?("error") 
				$error = @payment_data["error"]
			end 
		end
		if $error.length == 0 and @payment_data["payment_token"]["id"] != params["layer_pay_token_id"]
			$error = "Layer: received layer_pay_token_id and collected layer_pay_token_id doesnt match"
		end 
		if $error.length == 0 and format("%.2f",@payment_data["amount"].to_f)  != format("%.2f",params["layer_order_amount"].to_f)
			$error = "Layer: received amount and collected amount doesnt match"
		end
		if $error.length == 0 and @payment_data["payment_token"]["status"] != "paid"
			@status = "Transaction failed..."+@payment_data["payment_error_description"]
		elsif $error.length == 0
			@status = "Transaction Successful"
		end
		
 	end 
 	#end of response
	
	def create_payment_token(data,accesskey,secretkey,environment)		
		data = data.reject {|_,v| v.blank?}		
		return http_post(data,"/api/payment_token",accesskey,secretkey,environment)		
	end

	def get_payment_token(payment_token_id,accesskey,secretkey,environment)
		@response = {}
		if payment_token_id.length == 0 or payment_token_id == '' 
			@response= {"error" => "payment_token_id cannot be empty"}
		else
			@response = http_get("/api/payment_token/" + payment_token_id,accesskey,secretkey,environment)			
		end
		return @response
	end

	def get_payment_details(payment_id,accesskey,secretkey,environment)
		@response={}
		if payment_id.length == 0 or payment_id == '' 
			@response = {"error"=>"pyment_id cannot be empty"}
		else
			@response=http_get("/api/payment/"+payment_id,accesskey,secretkey,environment)			
		end
		return @response	
	end
	
	def http_post(data,route,accesskey,secretkey,environment)
		@response = ""
		@url = $BASE_URL_SANDBOX 
		if environment == "live" 
			@url = $BASE_URL_UAT 
		end 		
		@headers = {'Content-type': 'application/json',"Authorization":"Bearer "+accesskey+":"+secretkey}
		conn = Faraday.new(@url)
		@response = conn.post(route, data.to_json, @headers)
		return JSON.parse(@response.body)
	end 
  
	def http_get(route,accesskey,secretkey,environment)
		@response = ""
		@url = $BASE_URL_SANDBOX 
		if environment == "live" 
			@url = $BASE_URL_UAT 
		end
		@headers = {'Content-type': 'application/json',"Authorization":"Bearer "+accesskey+":"+secretkey}
		@response = Faraday.new(@url+route, headers: @headers).get			
		return JSON.parse(@response.body)
	end
	
	def create_hash(data,accesskey,secretkey) 		
		@pipeSeperatedString=accesskey+"|"+data["amount"]+"|"+data["id"]+"|"+data["mtx"]
		@digest = OpenSSL::Digest.new('sha256')
		return Base64.encode64(OpenSSL::HMAC.hexdigest(@digest, secretkey, @pipeSeperatedString)).gsub(/\n/, '')
	end

	def verify_hash(data,rec_hash,accesskey,secretkey)
		gen_hash = create_hash(data,accesskey,secretkey)		
		return gen_hash <=> rec_hash
	end
end

