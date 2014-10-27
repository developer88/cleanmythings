class User < ActiveRecord::Base

	has_many :slots

	validates :name, :email, :zip, :phone, :address, presence: true

end