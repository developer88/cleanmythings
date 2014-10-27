class Slot < ActiveRecord::Base

	belongs_to :slot_user

	validates :date, :start_at, :supplies_by_owner, presence: true
	validates :bathrooms, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5  }
	validates :bedrooms, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 5 }
	validates :how_often, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 4 }
	validates :supplies_by_owner, inclusion: { in: [true, false] }

end