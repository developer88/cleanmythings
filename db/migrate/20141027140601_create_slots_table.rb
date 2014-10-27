class CreateSlotsTable < ActiveRecord::Migration
  def change
    create_table :slots do |t|
    	t.integer  :user_id
    	t.float    :hours
    	t.boolean  :supplies_by_owner
    	t.integer  :bedrooms
    	t.integer  :bathrooms
    	t.integer  :how_often
    	t.datetime :date
    	t.time     :start_at
    	t.boolean  :cats
    	t.boolean  :dogs
    	t.boolean  :pets
    	t.string   :pets_describe
    	t.integer  :cleaning
        t.string   :priority

    	#t.timestamps we do not need this
    end
  end
end
