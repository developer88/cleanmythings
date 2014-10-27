class Slot < ActiveRecord::Base

	belongs_to :user

	validates :date, :start_at, :supplies_by_owner, :cleaning, presence: true
	validates :bathrooms, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5  }
	validates :bedrooms, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 5 }
	validates :how_often, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 4 }
	validates :cleaning, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 111111 }
	validates :supplies_by_owner, inclusion: { in: [true, false] }
	validates :cats, inclusion: { in: [true, false] }
	validates :dogs, inclusion: { in: [true, false] }
	validates :pets, inclusion: { in: [true, false] }
	validates :hours, numericality: true, if: Proc.new { |a| a.hours.present? }

	validates :priority, presence: true, if: :not_enough_time?

	# check if slot is available
	def available?
		# TODO
		true
	end

	# calculate necessary time to finish cleaning
	def time_recommend
		1.5 + (bedrooms.to_i * 0.5) + bathrooms.to_i + cleaning.to_s.chars.map(&:to_i).inject{|sum,x| sum + x }.to_i
	end

	# List of all available slots
	def self.available(params)
		[]
	end

	private

		# check if time for cleaning requested by user is non enought for full cleaning
		def not_enough_time?
			hours.present? && time_recommend > hours.to_f
		end

end