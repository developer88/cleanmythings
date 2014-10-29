require 'spec_helper'
require 'rails_helper'

RSpec.describe SlotsController, type: :controller do

	let(:time){ Time.now + 1.day }
    let(:tomorrow){ Time.utc(time.year, time.month, time.day, 10, 0)  }

	describe '#handle_error' do

		it 'should get "Error" message if raise param is passed' do
			get :index, raise: true
			resp = unsuccessful_response
			expect(resp["error"]).to eq('Error')
		end

	end

	describe '#index' do

		context 'should return list' do

			it 'with free slots' do
				get :index, slot: { supplies_by_owner: true, cleaning: 100001, bathrooms: 1, bedrooms: 2, hours: 3, date: tomorrow } 
				resp = successful_response
				expect(resp["slots"].size).to be > 0
				expect(resp["slots"].keys.first.include?(tomorrow.to_date.to_s)).to be true
			end

			it 'without free slots' do
				Slot.create!({hours: 4, start_at: tomorrow, how_often:0, team: "1"})
				Slot.create!({hours: 4, start_at: tomorrow, how_often:0, team: "2"})
				Slot.create!({hours: 4, start_at: tomorrow, how_often:0, team: "3"})
				get :index, slot: { bathrooms: 1, bedrooms: 1, how_often: 2, hours: 5, date: tomorrow } 
				resp = successful_response
				expect(resp["slots"][resp["slots"].keys.first].include?(tomorrow.to_json)).to be false		
			end

		end

	end

	describe '#create' do

		it 'should book free slot' do
			post :create, { user: {name: 'Andrey', email: 'someEmail@servcer.com', address: 'some street, some city', zip: '000000', phone: '+74443332222'}, slot: {hours: 4, start_at: tomorrow + Random.rand(6).hours, how_often:1} }
			resp = successful_response
			expect(resp["slot"]["id"].to_i).to eq(Slot.last.id)
			expect(resp["user"]["id"].to_i).to eq(User.last.id)
		end

		context 'should not book a slot' do

			it 'because of invalid user params' do
				post :create, {user: {name: 'Andrey', email: 'someEmail@servcer.com'} }
				resp = unsuccessful_response(400)
				expect(resp["errors"].size).to eq(3)
			end

			it 'because of there is no slots available for params given' do
				Slot.create!({hours: 4, start_at: tomorrow, how_often:0, team: "1"})
				Slot.create!({hours: 4, start_at: tomorrow, how_often:0, team: "2"})
				Slot.create!({hours: 4, start_at: tomorrow, how_often:0, team: "3"})
				post :create, { user: {name: 'Andrey', email: 'someEmail@servcer.com', address: 'some street, some city', zip: '000000', phone: '+74443332222'}, slot: {hours: 4, start_at: tomorrow, how_often:0} }
				resp = unsuccessful_response(400)
				expect(resp["errors"].size).to eq(1)
			end

			it 'because of invalid slot params' do
				post :create, { user: {name: 'Andrey', email: 'someEmail@servcer.com', address: 'some street, some city', zip: '000000', phone: '+74443332222'}, slot: {hours: 4, start_at: tomorrow + Random.rand(6).hours, how_often:1, bedrooms:7} }
				resp = unsuccessful_response(400)
				expect(resp["errors"].size).to eq(2)
			end

		end

	end

end