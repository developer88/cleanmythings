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

	def available?
		true
	end

end