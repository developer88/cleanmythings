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

  let(:time){ Time.now + 1.day }
  let(:tomorrow){ Time.utc(time.year, time.month, time.day, 10, 0)  }

  it 'should validate priority field if time requested is not enought' do
  	s = Slot.new({hours: 3, start_at: tomorrow, how_often:0, bathrooms: 4, bedrooms: 4})
  	expect(s.valid?).to be false
  	expect(s.errors.full_messages.size).to eq(1)
  end

  describe '#book' do

  	context 'with errors' do

  		it 'should return false because of time is occupied' do
  			Slot.create!({hours: 4, start_at: tomorrow, how_often:0, team: "1"})
  			Slot.create!({hours: 4, start_at: tomorrow, how_often:0, team: "2"})
  			Slot.create!({hours: 4, start_at: tomorrow, how_often:0, team: "3"})
  			slot = Slot.new({hours: 4, start_at: tomorrow, how_often:1})
  			expect(slot.valid?).to be false
  			expect(slot.errors.full_messages.size).to eq(1)
  		end

  		it 'should return false because of wrong params' do
  			slot = Slot.new({hours: 4, start_at: tomorrow + Random.rand(5).hours, how_often:5})
  			expect(slot.valid?).to be false
  			expect(slot.errors.full_messages.size).to eq(1)
  		end

  	end

  	context 'with no errors' do

  		it 'should successfully create new slot for one time cleaning' do
  			slot = Slot.new({hours: 4, start_at: tomorrow + Random.rand(6).hours, how_often:0})
  			expect(slot.valid?).to be true
  			expect(slot.book).to be true
  			expect(Slot.all.size).to eq(1)
  		end

   		it 'should successfully create new slot for weakly cleaning' do
   			slot = Slot.new({hours: 4, start_at: tomorrow + Random.rand(6).hours, how_often:1})
   			expect(slot.valid?).to be true
   			expect(slot.book).to be true
   			expect(Slot.all.size).to eq(3)
  		end 

  	end

  end

  describe '#available' do

  	context 'should return list of all available slots' do

  		it 'for proper how_often param' do
  			list = Slot.available({how_often: 0, hours: 3, date: tomorrow})
  			expect(list.is_a?(Hash)).to be true
  			expect(list.keys.size).to eq( TimeDifference.between(tomorrow, tomorrow + 3.months).in_days + 1  )
  		end

  		it 'for empty params' do
  			list = Slot.available
  			expect(list.is_a?(Hash)).to be true
  			expect(list.keys.size).to eq( TimeDifference.between(tomorrow, tomorrow + 3.months).in_days   )
  		end

  	end

  	context 'should return empty list because of' do

  	before do
  		@time1 = tomorrow + Random.rand(6).hours
  		@time2 = tomorrow + Random.rand(3).days
  	    Slot.new(bathrooms: 1, bedrooms: 1, how_often: 0, hours: 5, cleaning: 100000, start_at: @time1).book
  	    Slot.new(bathrooms: 1, bedrooms: 1, how_often: 0, hours: 5, cleaning: 100000, start_at: @time1).book
  	    Slot.new(bathrooms: 1, bedrooms: 1, how_often: 0, hours: 5, cleaning: 100000, start_at: @time1).book
  	    Slot.new(bathrooms: 1, bedrooms: 1, how_often: 0, hours: 5, cleaning: 100000, start_at: @time2).book
  	    Slot.new(bathrooms: 1, bedrooms: 1, how_often: 0, hours: 5, cleaning: 100000, start_at: @time2).book
  	    Slot.new(bathrooms: 1, bedrooms: 1, how_often: 0, hours: 5, cleaning: 100000, start_at: @time2).book 	    
  	end	  		

  		it 'no free slots for how_often param for weekly cleaning' do
	  		list = Slot.available({bathrooms: 1, bedrooms: 1, how_often: 2, hours: 5, date: @time1})
	  		expect(list.is_a?(Hash)).to be true
	  		expect(list.has_key?(@time1)).to be false
  		end

  		it 'no free slots for how_often param for one time cleaning' do
	  		list = Slot.available({bathrooms: 1, bedrooms: 1, how_often: 2, hours: 5, date: @time2})
	  		expect(list.is_a?(Hash)).to be true
	  		expect(list.has_key?(@time2)).to be false
  		end    				

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