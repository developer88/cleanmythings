require 'spec_helper'
require 'rails_helper'

RSpec.describe SlotsController, type: :controller do

	describe '#handle_error' do

		it 'should get "Error" message if raise param is passed' do
			get :index, raise: true
			resp = unsuccessful_response
			expect(resp["error"]).to eq('Error')
		end

	end

	describe '#index' do

		context 'there are free slots' do

		end

		context 'there is no any free slots' do

		end

	end

	describe '#create' do

		context 'should proceed' do

		end

		context 'should not proceed' do

			it 'because of invalid user params' do
				post :create, {user: {name: 'Andrey', email: 'someEmail@servcer.com'} }
				resp = unsuccessful_response(400)
				expect(resp["errors"].size).to eq(3)
			end

			it 'because of there is no slots available for params given' do
				post :create, { user: {name: 'Andrey', email: 'someEmail@servcer.com', address: 'some street, some city', zip: '000000', phone: '+74443332222'}, slot: { supplies_by_owner: true, cleaning: 100001, bathrooms: 1, bedrooms: 2 } }
				resp = unsuccessful_response(404)
				expect(resp["error"]).to eq('Slot is not available')
			end

			it 'because of invalid slot params' do
				post :create, { user: {name: 'Andrey', email: 'someEmail@servcer.com', address: 'some street, some city', zip: '000000', phone: '+74443332222'}, slot: { supplies_by_owner: true, cleaning: 100001, bathrooms: 1, bedrooms: 2 } }
				resp = unsuccessful_response(400)
				expect(resp["errors"].size).to eq(6)
			end

		end

	end

end