class CreateSlotsTable < ActiveRecord::Migration
  def change
    create_table :slots do |t|
    	t.integer  :slot_user_id
    	t.float    :hours
    	t.boolean  :supplies_by_owner
    	t.integer  :bedrooms
    	t.integer  :bathrooms
    	t.integer  :how_often
    	t.datetime :date
    	t.time     :start_at

    	#t.timestamps we do not need this
    end
  end
end