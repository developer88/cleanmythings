class SlotsController < ApplicationController

	def index

	end

	def create

	end

	private

		def slot_params
	      params.permit(:type, :hours, :supplies_by_owner)
	    end

end
