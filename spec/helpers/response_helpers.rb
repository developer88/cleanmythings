module ResponseHelpers

	def successful_response
		expect_response_to_return(200)
	end

	def expect_response_to_return(code = 200)
		expect(response.code.to_i).to eq(code)
		JSON.parse(response.body)
	end

	def unsuccessful_response(code = 500)
		expect_response_to_return(code)
	end	

end