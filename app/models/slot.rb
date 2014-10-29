class Slot < ActiveRecord::Base

	# Settings
	# It is better to store it in yml file, but because of little time for the task and lots of work to do at my job i leave it like this:
	TEAM_SIZE = 3 # Count of cleaning team available
	CALENDAR_SIZE = 3.months # Slots booking period
	START_TIME = 8.hours # Time to start a working day
	END_TIME = 17.hours # Last time to start cleaning
	MIN_LENGTH = 1.5 # Minimum cleaning length
	WORKING_DAY_LENGTH = END_TIME - START_TIME # Length of working day to start cleaning
	COUNT_OF_ITERATION = 2 # Just invented by myself. Number of repeated actions
	DAYS_OF_WEEK = 7 # Number of days in week
	GAP = 1.hour # Value on how start_time for slot can differ  

	# Some helpers here

	# Round hour to get rid of minutes
	ROUND_HOUR = ->(time){ TimeDifference.between(time, Time.utc(time.year, time.month, time.day, time.hour, 0) ).in_minutes > 0 ? Time.utc(time.year, time.month, time.day, time.hour + 1, 0) : time }
	
	# Get occupied slots from DB
	scope :occupied_slots, ->(date) { where("start_at <= ?", date + CALENDAR_SIZE).where("end_at >= ?", date).order('start_at ASC') }
	
	# Check if current slot is inside GAP (+- 1.hour)
	INSIDE_GAP = ->(current, compare){ current >= Time.utc(current.year, current.month, current.day, compare.hour, compare.min) - GAP && current <= Time.utc(current.year, current.month, current.day, compare.hour, compare.min) + GAP }
	
	# Convert time to UTC
	TO_UTC = ->(time){ Time.utc(time.year, time.month, time.day, time.hour, time.min) }

	# Model definition
	belongs_to :user

	# Just some system fields
	attr_reader :skip_validation
	attr_accessor :date

	# Validations
	validates :bathrooms, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5  }
	validates :bedrooms, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 5 }
	validates :how_often, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 4 } # 0 for 1 time, 1 for 1 week, 2 for 2 weeks etc
	validates :cleaning, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 111111 }
	validates :supplies_by_owner, inclusion: { in: [true, false] }, if: Proc.new { |a| a.supplies_by_owner.present? }
	validates :cats, inclusion: { in: [true, false] }, if: Proc.new { |a| a.cats.present? }
	validates :dogs, inclusion: { in: [true, false] }, if: Proc.new { |a| a.dogs.present? }
	validates :pets, inclusion: { in: [true, false] }, if: Proc.new { |a| a.pets.present? }
	validates :hours, numericality: true, if: Proc.new { |a| a.hours.present? }
	validates :priority, presence: true, if: :not_enough_time?
	validates :team, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: TEAM_SIZE }, if: Proc.new { |a| a.team.present? }
	validate  :is_available, if: Proc.new { |a| !@skip_validation }

	before_save :update_end_at_date

	# book current slot
	def book
		return false unless valid?
		# Find all dates for slots (especially if we ask for repeated cleaning)
		dates = [start_at]
		COUNT_OF_ITERATION.times{|i| dates << (start_at + (DAYS_OF_WEEK * (i+1)*how_often).days) } if how_often > 0
		teams = []
		# Now find available teams for each date
		dates = dates.map{|d| [d, Slot.available_for_day(d, {hours: hours, start_at: start_at, flatten: false}, Slot.occupied_slots(d)).reject{|k,v| v.size == 0 }] }
		self.team = dates.first[1].keys.first.to_i
		# Now save our slot + other slots based on how_often param
		ActiveRecord::Base.transaction do
			dates.each_with_index do |d, index|
				next if index == 0	
				slot = Slot.new(self.attributes.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo})
				slot.start_at = d[0]
				slot.team = dates[index][1].keys.first.to_i
				slot.skip_validation = true
				slot.save!
			end
			save!
		end
	end

	# calculate necessary time to finish cleaning
	def time_recommend
		MIN_LENGTH + (bedrooms.to_i * 0.5) + bathrooms.to_i + cleaning.to_s.chars.map(&:to_i).inject{|sum,x| sum + x }.to_i
	end

	def skip_validation=(value)
		@skip_validation = value
	end

	# List of all available slots
	# Params needed:
	# bathrooms
	# bedrooms
	# cleaning
	# how_often
	# hours
	# date
	def self.available(params = {})
		# Filter incoming params
		params = {bathrooms: 1, bedrooms: 0, cleaning: 0, how_often: 0}.merge(params)
		params[:hours] = Slot.new(params).time_recommend unless params[:hours] # check for minimum time TODO
		params[:date] = TO_UTC.call(Time.now) unless params[:date]
		params[:date] = ROUND_HOUR.call(TO_UTC.call(Time.now) > params[:date] ? TO_UTC.call(Time.now) : params[:date])
		
		# Start that ... hm... magic
		cur_date = params[:date] 
		slots = Slot.occupied_slots(cur_date)
		list = {}

		# To reduce amount of operations i do it with 2 steps
		#
		# 1) find any free slots based on hours required for cleaning for CALENDAR_SIZE days
		while cur_date <= (params[:date] + CALENDAR_SIZE)
			
			# check if current_date is free
			to_day = Slot.available_for_day(cur_date, params, slots)
			list[Time.utc(cur_date.year, cur_date.month, cur_date.day)] = to_day if to_day.size > 0	

			cur_date = Time.utc(cur_date.year, cur_date.month, cur_date.day) + 1.day

		end
		list.flatten.uniq
		# now we have a list of free slots for current_time + 3 months

		# 2) now if how_often param is more than 0 then we should find out days that would be free for COUNT_OF_ITERATION times in the future
		results = {}
		if params[:how_often] > 0			
			list.keys.each do |day|
				list[day].each do |slot|
					slots = {}
					COUNT_OF_ITERATION.times do |i|
					    next_date = day + ((i+1)*DAYS_OF_WEEK*params[:how_often]).days
					    break unless list.has_key?(next_date)
					    if list[next_date].find_all{|s| INSIDE_GAP.call(s, slot) }.size > 0   
					    	slots[slot] = 0 unless slots.has_key?(slot)
					    	slots[slot] += 1 
					    end
					end
					results[day] = [] unless results.has_key?(day)
					slots.keys.each{|s| slots[s] == COUNT_OF_ITERATION ? results[day] << s : nil }					
				end
			end
		else
			results = list
		end	
		# Now clear all empty keys and return Hash
		results.reject{|k,v| v.size == 0 }	
	end

	# Find all posible time gaps (slots) inside particular day
	def self.available_for_day(current, params = {}, collection = nil)		

		params = {flatten: true}.merge(params)
		
		list = []
		teams = {}

		# Some helpers
		start_time = ->(time){ Time.utc(time.year, time.month, time.day) + START_TIME }
		end_time = ->(time){ Time.utc(time.year, time.month, time.day) + END_TIME }
		start_time_for_today = current > start_time.call(current) ?  current : start_time.call(current)  #->(time){ start_time.call(time) > time ? start_time.call(time) : time }

		return [] if params[:hours].to_i == 0
		return [] if current > end_time.call(current)

		# Initialize array with teams and fill it with occupied slots
		TEAM_SIZE.times{|t| teams[(t+1).to_s] = []} # initialize array for each team
		collection = Slot.all.order('date ASC') unless collection # get slots collection if needed
		collection = collection.find_all{|s| Time.at(s.start_at).to_date == Time.at(current).to_date }

		if collection.size
			# find uccupied slots for current date and sort it out by each team
			collection.each{|s| teams[s.team.to_s] << [s.start_at, (s.start_at + s.hours.hours)] } 
			TEAM_SIZE.times{|t| teams[(t+1).to_s].size > 0 ? (teams[(t+1).to_s].unshift([start_time.call(current),  start_time.call(current)])) : nil }
		end 

		# Now for each team create an array with free slots
		# If start_at param is provided then we limit slots by the time specified in that param
		TEAM_SIZE.times do |i|
			# for each team find free slot based on hours params
			if teams[(i+1).to_s].size == 0 
				# If team has a free day
				teams[(i+1).to_s] = []
				((end_time.call(current) - start_time_for_today) / 1.hour).round.times{|h| teams[(i+1).to_s] << (start_time_for_today + h.hours).to_time } unless params[:start_at]
				teams[(i+1).to_s] << params[:start_at] if params[:start_at]
			else
				# For day with slots
				new_values = []
				teams[(i+1).to_s].each_with_index do |item, index|

					date1 = item[1] unless params[:start_at]
					date1 = params[:start_at] if params[:start_at]
					date2 = teams[(i+1).to_s][index+1][0] if index+1 < teams[(i+1).to_s].size 
					date2 = end_time.call(item[0]) + params[:hours].hours if index+1 == teams[(i+1).to_s].size 

					if TimeDifference.between(date1, date2).in_hours >= params[:hours] && date1 > current

						((end_time.call(current) - date1) / 1.hour).round.times do |t|
							dt = date1 + t.hour + params[:hours].hours
							add = false
							add = true if (dt < date2)
							add = false if params[:start_at].present? && !INSIDE_GAP.call(dt, params[:start_at]) && add
							new_values << date1 + t.hour if add
						end

					end

				end
				teams[(i+1).to_s] = new_values
			end
		end

		# If we need to flatten array (to get rid of team numbers)
		if params[:flatten]
			results = []
			teams.keys.each{|k,v| results << teams[k] }
			return results.flatten.uniq.sort 
		end
		
		# Return array as is
		teams unless params[:flatten]
	end	

	private

		# Check if time for cleaning requested by user is non enought for full cleaning
		def not_enough_time?
			hours.present? && time_recommend > hours.to_f
		end

		# Calculate end date for slot
		def update_end_at_date
			self.end_at = start_at + hours.hours
		end

		# Check if this slot is available
		def is_available 
			return false unless start_at
			self.start_at = ROUND_HOUR.call(start_at)

			date = Time.utc(start_at.year, start_at.month, start_at.day)
			# Find all slots and check if we have key with start_at date and there is start_at slot inside date's array
			@slots = Slot.available(self.attributes.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}.merge({date: start_at}))
			status = @slots.has_key?(date) && @slots[date].include?(start_at)
			
			errors.add(:start_at, "date is not available") unless status
			status
		end

end