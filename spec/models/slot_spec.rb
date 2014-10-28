require 'spec_helper'
require 'rails_helper'

RSpec.describe Slot, type: :model do

  #it { should validate_presence_of(:supplies_by_owner) }
  #it { should validate_presence_of(:date) }
  #it { should validate_presence_of(:start_at) }
  it { should validate_numericality_of(:hours) }

  it { should validate_numericality_of(:bathrooms).only_integer.is_greater_than_or_equal_to(1).is_less_than_or_equal_to(5) }
  it { should validate_numericality_of(:bedrooms).only_integer.is_greater_than_or_equal_to(0).is_less_than_or_equal_to(5) }
  it { should validate_numericality_of(:how_often).only_integer.is_greater_than_or_equal_to(0).is_less_than_or_equal_to(4) }
  it { should validate_numericality_of(:cleaning).only_integer.is_greater_than_or_equal_to(0).is_less_than_or_equal_to(111111) }
  it { should validate_numericality_of(:team).only_integer.is_greater_than_or_equal_to(1).is_less_than_or_equal_to(3) }

  it { should belong_to(:user) }

  it 'should validate priority field if time requested is not enought' do

  end

  describe '#available?' do

  	it 'should notify that slot is available' do

  	end

  	it 'should notify that slot is not available' do

  	end

  end

  describe '#available' do

  	before do
  		2.times do
  			Slot.create(bathrooms: 1, bedrooms: 1, how_often: 0, hours: 5, cleaning: 100000, start_at: 10.hours, date: Time.now + (Random.rand(10)).days)
  		end
  	end	

  	context 'should return list of all available slots' do

  		it 'for proper how_often param' do
  			list = Slot.available({how_often: 0, hours: 5})
  			expect(list.is_a?(Array)).to be true
  			expect(list.size).to eq(2)
  		end

  		it 'for empty params' do
  			list = Slot.available
  			expect(list.is_a?(Array)).to be true
  			expect(list.size).to eq(2)
  		end

  	end

  	it 'should return list of all available slots' do
  		
  	end

  	context 'should return empty list because of' do

  		it 'no free slots for how_often param' do
	  		list = Slot.available({bathrooms: 1, bedrooms: 1, how_often: 2, hours: 5})
	  		expect(list.is_a?(Array)).to be true
	  		expect(list.size).to eq(2)
  		end

  		it 'no free slots for how_often param' do
	  		list = Slot.available({bathrooms: 1, bedrooms: 1, how_often: 2, hours: 5})
	  		expect(list.is_a?(Array)).to be true
	  		expect(list.size).to eq(2)
  		end  		

  	end

  	it 'wrong params' do

  	end

  end

  describe '#time_recommend' do

  	it 'should return proper recommend time for full cleaning with laundry' do
  		slot = Slot.new(bathrooms: 1, bedrooms: 2, cleaning: 1)
  		expect(slot.time_recommend).to eq(4.5)
  	end

  	it 'should return proper recommend time for full cleaning with laundry + interior walls' do
  		slot = Slot.new(bathrooms: 1, bedrooms: 2, cleaning: 100001)
  		expect(slot.time_recommend).to eq(5.5)
  	end

  end


end