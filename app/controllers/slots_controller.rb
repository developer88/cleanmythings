class SlotsController < ApplicationController

    # Default for responces
    respond_to :json
    layout false
    respond_to :json

    # Handle all error messages
    around_filter :handle_error

    # List of all available slots
	def index
		list = Slot.available(slot_params[:slot])
		return do_respond({error: "No Slots available for params provided"}, 404) if list.size == 0
		do_respond({slots: list})
	end

	# Booking a slot
	def create
		user = User.new(slot_params[:user])
		return do_respond({errors: user.errors.full_messages}, 400) unless user.save
		slot = Slot.new(slot_params[:slot])
		slot.user = user
		return do_respond({errors: slot.errors.full_messages}, 400) unless slot.save
		return do_respond({error: "Slot is not available"}, 404) unless slot.available? # I decided to make it with another line to return user 404 instead of 400 in case of slot is not available
		do_respond({slot: slot, user: user})
	end

	private

		def slot_params
	      params.permit(:raise, slot: [:hours, :supplies_by_owner, :bedrooms, :bathrooms, :how_often, :date, :start_at, :cats, :dogs, :pets, :pets_describe, :cleaning], user:[:name, :email, :address, :zip, :phone])
	    end

	    # Handle any exception and return error key in JSON object
	    def handle_error
          begin
            raise "Error" if slot_params.include?(:raise) && Rails.env.test? # this is for testing only to simulate unhandled exceptions
            yield             
          rescue Exception => e  
            do_respond({error: e.message}, 500)           
          end
	    end

        # Response with json object
        def do_respond(obj, code = 200)
          render :json => obj.transform_keys{ |key| key.to_s.downcase }.to_json, status: code 
        end        	    

end
