class Slot < ActiveRecord::Base

	# Settings
	# It is better to store it in yml file, but because of little time for the task and lots of work to do at my job i leave it like this:
	TEAM_SIZE = 3 # Count of cleaning team available
	CALENDAR_SIZE = 3.months # Slots booking period
	START_TIME = 8.hours # Time to start a working day
	END_TIME = 17.hours # Last time to start cleaning
	MIN_LENGTH = 1.5 # Minimum cleaning length
	WORKING_DAY_LENGTH = END_TIME - START_TIME # Length of working day to start cleaning
	COUNT_OF_ITERATION = 3 # Just invented by myself. Number of repeated actions
	DAYS_OF_WEEK = 7 # Number of days in week

	# Model definition
	belongs_to :user

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

	# check if slot is available
	def available?



		# TODO
		true
	end

	# calculate necessary time to finish cleaning
	def time_recommend
		MIN_LENGTH + (bedrooms.to_i * 0.5) + bathrooms.to_i + cleaning.to_s.chars.map(&:to_i).inject{|sum,x| sum + x }.to_i
	end

	# List of all available slots
	# Params needed:
	# bathrooms
	# bedrooms
	# cleaning
	# how_often
	# hours
	def self.available(params = {})
		cur_date = Time.now
		params = {bathrooms: 1, bedrooms: 0, cleaning: 0, how_often: 0}.merge(params)
		params[:hours] = Slot.new(params).time_recommend unless params[:hours]

		#available_for_day = ->(current, needle){ slots.detect{|s| Time.at(needle).to_date === Time.at(current).to_date }.detect{|s| () || () } }


		#params[:date] = Time.parse(params[:date]) if params[:date]
		#options = {start_at: 8.hours, date: Time.now, how_often: 0}.merge(params)

		slots = Slot.where("date <= ?", cur_date + CALENDAR_SIZE).where("date >= ?", date).order('date ASC')
		list = []
		while cur_date <= (Time.now + CALENDAR_SIZE)
			
			# check if current_date is free
			to_day = Slot.available_for_day(cur_date, slots)
			next if to_day.size == 0

			# check for future date availability
			if params[:how_often] > 0
				next if COUNT_OF_ITERATION.times{|i| Slot.available_for_day(cur_date + (i*DAYS_OF_WEEK*params[:how_often]).days, slots).size > 0 ? 1 : nil }.compact.size != COUNT_OF_ITERATION
			end
			list << to_day

			cur_date = cur_date + 1.day
		end
		list.flatten.uniq
	end

	# Find all posible time gaps (slots) inside 'current' day
	def self.available_for_day(current, collection = nil)
		list = []
		teams = {}
		TEAM_SIZE.times{|t| teams[t.to_s] = []} # initialize array for each team
		collection = Slot.all.order('date ASC') unless collection # get slots collection if needed
		collection.detect{|s| Time.at(s.date).to_date === Time.at(current).to_date }.each{|s| teams[s.team.to_i] << [s.start_at, (s.start_at + s.hours.hours)] } # find uccupied slots for current date and sort it out by each team
		TEAM_SIZE.times do |i|
			# for each team find free slot
			# TODO
			#teams[i.to_s].each_with_index{|s, index|  index == 0 ? () : ()      }


			#list << collection.detect{|s| teams[i.to_s] }
		end
		list.flatten.uniq
	end	

	private

		# check if time for cleaning requested by user is non enought for full cleaning
		def not_enough_time?
			hours.present? && time_recommend > hours.to_f
		end

end