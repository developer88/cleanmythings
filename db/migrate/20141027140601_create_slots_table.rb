class CreateSlotsTable < ActiveRecord::Migration
  def change
    create_table :slots do |t|
    	t.integer  :user_id
    	t.float    :hours
    	t.boolean  :supplies_by_owner, default: false
    	t.integer  :bedrooms, default: 0
    	t.integer  :bathrooms, default: 1
    	t.integer  :how_often, default: 0
    	t.datetime :end_at
    	t.datetime :start_at        
    	t.boolean  :cats, default: false
    	t.boolean  :dogs, default: false
    	t.boolean  :pets, default: false
    	t.string   :pets_describe
    	t.integer  :cleaning, default: 0
        t.string   :priority
        t.integer  :team, default: 1
    end
  end
end
