class CreateSlotsTable < ActiveRecord::Migration
  def change
    create_table :slots do |t|
    	t.integer  :user_id
    	t.float    :hours
    	t.boolean  :supplies_by_owner, default: false
    	t.integer  :bedrooms, default: 0
    	t.integer  :bathrooms, default: 1
    	t.integer  :how_often, default: 0
    	t.datetime :date
    	t.datetime :start_at
    	t.boolean  :cats, default: false
    	t.boolean  :dogs, default: false
    	t.boolean  :pets, default: false
    	t.string   :pets_describe
    	t.integer  :cleaning, default: 0
        t.string   :priority
        t.string   :team, default: 1

    	#t.timestamps we do not need this
    end
  end
end
