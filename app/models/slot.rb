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

	ROUND_HOUR = ->(time){ TimeDifference.between(time, Time.utc(time.year, time.month, time.day, time.hour, 0) ).in_minutes > 0 ? Time.utc(time.year, time.month, time.day, time.hour + 1, 0) : time }
	scope :occupied_slots, ->(date) { where("start_at <= ?", date + CALENDAR_SIZE).where("end_at >= ?", date).order('start_at ASC') }
	INSIDE_GAP = ->(current, compare){ current >= Time.utc(current.year, current.month, current.day, compare.hour, compare.min) - GAP && current <= Time.utc(current.year, current.month, current.day, compare.hour, compare.min) + GAP }
	TO_UTC = ->(time){ Time.utc(time.year, time.month, time.day, time.hour, time.min) }

	# Model definition
	belongs_to :user

	attr_reader :skip_validation
	attr_accessor :date

	#validates :date, :start_at, :supplies_by_owner, :cleaning, presence: true
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
	#before_save :is_available

	# book current slot
	def book
		return false unless valid?
		dates = [start_at]
		COUNT_OF_ITERATION.times{|i| dates << (start_at + (DAYS_OF_WEEK * (i+1)*how_often).days) } if how_often > 0
		teams = []
		#puts dates.inspect
		dates = dates.map{|d| [d, Slot.available_for_day(d, {hours: hours, start_at: start_at, flatten: false}, Slot.occupied_slots(d)).reject{|k,v| v.size == 0 }] }
		TEAM_SIZE.times do |team|
			count = 0
			dates.each{|d| d[1].has_key?( (team+1).to_s ) ? count = count + 1 : nil }
			teams << team + 1 if count == TEAM_SIZE
		end
		self.team = teams.first
		#raise teams.inspect	
		self.team = 1 unless self.team
		ActiveRecord::Base.transaction do
			dates.each_with_index do |d, index|
				next if index == 0			
				#puts d[0]
				slot = Slot.new(self.attributes.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo})
				slot.start_at = d[0]
				slot.skip_validation = true
				#raise slot.inspect unless slot.valid?
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
	def self.available(params = {})
		

		params = {bathrooms: 1, bedrooms: 0, cleaning: 0, how_often: 0}.merge(params)
		params[:hours] = Slot.new(params).time_recommend unless params[:hours] # check for minimum time TODO
		params[:date] = TO_UTC.call(Time.now) unless params[:date]
		params[:date] = ROUND_HOUR.call(TO_UTC.call(Time.now) > params[:date] ? TO_UTC.call(Time.now) : params[:date])
		#params[:limit] = CALENDAR_SIZE
		#params[:limit] = (params[:how_often].to_i * DAYS_OF_WEEK * COUNT_OF_ITERATION).days
		#params[:limit] = CALENDAR_SIZE if params[:limit] == 0.days || params[:limit] > CALENDAR_SIZE
		cur_date = params[:date] 
		#puts cur_date
		#available_for_day = ->(current, needle){ slots.detect{|s| Time.at(needle).to_date === Time.at(current).to_date }.detect{|s| () || () } }


		#params[:date] = Time.parse(params[:date]) if params[:date]
		#options = {start_at: 8.hours, date: Time.now, how_often: 0}.merge(params)

		slots = Slot.occupied_slots(cur_date) #Slot.where("start_at <= ?", cur_date + CALENDAR_SIZE).where("end_at >= ?", cur_date).order('start_at ASC')
		#puts slots.size
		list = {}
		# To reduce amount of operations i do it with 2 steps
		#
		# 1) find any free slots based on hours required for cleaning for CALENDAR_SIZE days
		while cur_date <= (params[:date] + CALENDAR_SIZE)
			
			# check if current_date is free
			to_day = Slot.available_for_day(cur_date, params, slots)
			#puts to_day.inspect
			list[Time.utc(cur_date.year, cur_date.month, cur_date.day)] = to_day if to_day.size > 0	

			cur_date = Time.utc(cur_date.year, cur_date.month, cur_date.day) + 1.day
		end
		list.flatten.uniq
		#puts list.inspect
		#return list

		# 2) now if how_often param is more than 0 then we should find out days that would be free for COUNT_OF_ITERATION times in the future
		results = {}
		if params[:how_often] > 0			
			list.keys.each do |day|
				list[day].each do |slot|
					slots = {}
					#puts "!!!!! FOR SLOT #{slot}"
					COUNT_OF_ITERATION.times do |i|
					    next_date = day + ((i+1)*DAYS_OF_WEEK*params[:how_often]).days
					    #puts list.inspect
					    #puts day
					   # puts next_date
					  # puts next_date
					    break unless list.has_key?(next_date)
					    
					    #puts "sss"
					    #list[next_date].each{|s| puts "#{slot} : #{s} >= #{Time.new(s.year, s.month, s.day, slot.hour, slot.min) - GAP} && #{s} <= #{Time.new(s.year, s.month, s.day, slot.hour, slot.min) + GAP}" }
					    #puts list[next_date].find_all{|s| s >= slot - GAP && s <= slot + GAP }.size.inspect
					    if list[next_date].find_all{|s| INSIDE_GAP.call(s, slot) }.size > 0   #s >= Time.new(s.year, s.month, s.day, slot.hour, slot.min) - GAP && s <= Time.new(s.year, s.month, s.day, slot.hour, slot.min) + GAP }.size > 0
					    	slots[slot] = 0 unless slots.has_key?(slot)
					    	slots[slot] += 1 
					    end
					end
					#puts slots.inspect
					results[day] = [] unless results.has_key?(day)
					slots.keys.each{|s| slots[s] == COUNT_OF_ITERATION ? results[day] << s : nil }					
				end
			end
		else
			results = list
		end
		#list.reject{|k,v| v.size == 0 }	
		results.reject{|k,v| v.size == 0 }	
	end

	# Find all posible time gaps (slots) inside 'current' day
	def self.available_for_day(current, params = {}, collection = nil)		

		params = {flatten: true}.merge(params)
		
		list = []
		teams = {}

		start_time = ->(time){ Time.utc(time.year, time.month, time.day) + START_TIME }
		end_time = ->(time){ Time.utc(time.year, time.month, time.day) + END_TIME }
		start_time_for_today = current > start_time.call(current) ?  current : start_time.call(current)  #->(time){ start_time.call(time) > time ? start_time.call(time) : time }

		#puts "#{current} == #{start_time.call(current)}"

		return [] if params[:hours].to_i == 0
		return [] if current > end_time.call(current)

		#puts start_time_for_today

		TEAM_SIZE.times{|t| teams[(t+1).to_s] = []} # initialize array for each team
		#puts collection.inspect
		collection = Slot.all.order('date ASC') unless collection # get slots collection if needed
		collection = collection.find_all{|s| Time.at(s.start_at).to_date == Time.at(current).to_date }
		
#puts collection.inspect
		if collection.size
			# find uccupied slots for current date and sort it out by each team
			collection.each{|s| teams[s.team.to_s] << [s.start_at, (s.start_at + s.hours.hours)] } 
			TEAM_SIZE.times{|t| teams[(t+1).to_s].size > 0 ? (teams[(t+1).to_s].unshift([start_time.call(current),  start_time.call(current)])) : nil }
		end 
		#puts teams.inspect
		#puts current
		TEAM_SIZE.times do |i|
			# for each team find free slot based on hours params
			if teams[(i+1).to_s].size == 0 
				teams[(i+1).to_s] = []
				#puts "empty? #{(i+1)}"
				# For empty team's day
				#slots = ((end_time.call(current) - start_time_for_today) / 1.hour).round.divmod(params[:hours])
				#puts "#{end_time.call(current)} - #{start_time_for_today} => #{slots.inspect}"
				#puts (i+1).to_s
				#puts teams.inspect
				#puts teams[(i+1).to_s].inspect

				((end_time.call(current) - start_time_for_today) / 1.hour).round.times{|h| teams[(i+1).to_s] << (start_time_for_today + h.hours).to_time } unless params[:start_at]
				teams[(i+1).to_s] << params[:start_at] if params[:start_at]


				#(slots[0] + (slots[1] > 0 ? 1 : 0)).times do |index|
				#	list << (start_time_for_today + (index * params[:hours]).hours).to_time
				#end
			else
				# For day with slots
				#puts teams.inspect
				new_values = []
				teams[(i+1).to_s].each_with_index do |item, index|
					#date1 = Time.utc(item[0].year, item[0].month, item[0].day) + START_TIME if index == 0
					#date2 = item[0] if index != teams[(i+1).to_s].size 

					#date1 = teams[(i+1).to_s][index-1][1] if index > 0 
					#date2 = Time.utc(item[0].year, item[0].month, item[0].day) + END_TIME + params[:hours].hours if index == teams[(i+1).to_s].size 


					#list << date1 if TimeDifference.between(date1, date2).in_hours >= params[:hours] && date1 > current
					#puts TimeDifference.between(date1, date2).in_hours >= params[:hours]
	
					date1 = item[1] unless params[:start_at]
					date1 = params[:start_at] if params[:start_at]
					date2 = teams[(i+1).to_s][index+1][0] if index+1 < teams[(i+1).to_s].size 
					date2 = end_time.call(item[0]) + params[:hours].hours if index+1 == teams[(i+1).to_s].size 
					if TimeDifference.between(date1, date2).in_hours >= params[:hours] && date1 > current
						#slots = ((end_time.call(current) - date1) / 1.hour).round.divmod(params[:hours]) 
						#(slots[0] + (slots[1] > 0 ? 1 : 0)).times do |index|
						#	#puts index
						#	new_values << (date1 + (index  * params[:hours]).hours).to_time
						#end
						#list << date1 if TimeDifference.between(date1, date2).in_hours >= params[:hours] && date1 > current

						#puts end_time.call(current)
						((end_time.call(current) - date1) / 1.hour).round.times do |t|
							dt = date1 + t.hour + params[:hours].hours
							add = false
							add = true if (dt < date2)
							add = false if params[:start_at].present? && !INSIDE_GAP.call(dt, params[:start_at]) && add
							new_values << date1 + t.hour if add
						end





					end
					#puts TimeDifference.between(date1, date2).in_hours >= params[:hours]




					#date1 = [teams[i.to_s][index-1][1]



					#date1 = Time.utc(item[0].year, item[0].month, item[0].day) + END_TIME  if index == teams[i.to_s].size 
					#date1 = item[0] if index > 0 && index != teams[i.to_s].size 
					#
					#date2 = item[0] if index == 0
					#date2 = item[0] if index > 0 && index != teams[i.to_s].size 
					#date2 = 


					#puts TimeDifference.between(date1, date2).in_hours
					#list << [START_TIME, item[0]] if (((item[0] - START_TIME) / 1.hour).round > params[:hours]) && index == 0 # from the beginning of the day
					#list << [teams[i.to_s][index-1][1], item[0]] if (( (item[0] - teams[i.to_s][index-1][1]) / 1.hour  ).round > params[:hours]) && index > 0 && index < teams[i.to_s].size # between occupied slots
					#list << [item[1], item[1] + params[:hours].hours] if index == teams[i.to_s].size && ((END_TIME - item[1]) / 1.hour).round  > 0 # till end of the day
				end
				teams[(i+1).to_s] = new_values
			end
		end
		#puts teams.inspect
		if params[:flatten]
			results = []
			teams.keys.each{|k,v| results << teams[k] }
			#puts results.flatten.uniq.sort.inspect
			return results.flatten.uniq.sort 
		end
		
		teams unless params[:flatten]
	end	

	private

		# check if time for cleaning requested by user is non enought for full cleaning
		def not_enough_time?
			hours.present? && time_recommend > hours.to_f
		end

		def update_end_at_date
			self.end_at = start_at + hours.hours
		end

		def is_available 
			return false unless start_at
			#return true # TODO
			#puts start_at
			#puts "111"
			self.start_at = ROUND_HOUR.call(start_at)
			#puts start_at

			date = Time.utc(start_at.year, start_at.month, start_at.day)
			@slots = Slot.available(self.attributes.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}.merge({date: start_at}))
			status = @slots.has_key?(date) && @slots[date].include?(start_at)
			#status = false if !@slots.has_key?(date) || (@slots.has_key?(date) && @slots[date].include?(start_at))
			#status = false if @slots.has_key?(date) && @lost[date].include?(start_at)
			#puts "GOOD!!!"
			#puts @slots[date].inspect
			#puts status
			
			errors.add(:start_at, "date is not available") unless status
			status
		end

end