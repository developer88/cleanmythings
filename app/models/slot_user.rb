class SlotUser < ActiveRecord::Base

	has_many :slots

	#attr_accessor :name, :email, :zip, :phone, :address
	validates :name, :email, :zip, :phone, :address, presence: true

end