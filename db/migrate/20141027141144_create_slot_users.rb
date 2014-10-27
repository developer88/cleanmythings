class CreateSlotUsers < ActiveRecord::Migration
  def change
    create_table :slot_users do |t|
    	t.string  :name
    	t.string  :email
    	t.string  :address
    	t.string  :zip
    	t.string  :phone
    end
  end
end
