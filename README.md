# Clean My Things

Used RoR and SQLite:
*  First cause this is my favorite framework on ruby.
*  Second cause it fits well for that little task.

Used RSpec and Shoulda:
*  First is convinient and amazing way to test everything in Ruby world
*  Second is just a sugar

## Task

Explain shortly how you will do the following (make appropriate drawings or documentation):

###### Identify all necessary parameter that are transmitted to the backend end-point, in order to receive all available time slots 

Look at [slots_controller.rb](https://github.com/developer88/cleanmythings/blob/master/app/controllers/slots_controller.rb "slots_controller.rb") for main API methods.

I decided to create 2 methods:

* 'index' which returns JSON with list of all free slots. This method requests slot params which are: :hours - time needed for cleaning and :bathrooms, :bedrooms, :cleaning - extra task for cleaning, :how_often - all these items needed to generate recommended length (hours param) of cleaning, :date - to specify date
* 'create' which books selected free slot for user. This method requests slot params from 'index' method and user params which are: :name, :email, :address, :zip, :phone. I didn't implement validation for phone, email, proper zip code + :start_at for slots param to specify time to start cleaning.

###### Clarify in which step the backend function should be called

If we talk about [homejoy.com](https://www.homejoy.com "https://www.homejoy.com") then backend function is requested right after user fills in all his contact data and hits 'Next' button. Then several requests are made:

*  POST https://www.homejoy.com/api/v2/book/pricing/json for pricing
*  POST https://www.homejoy.com/api/v2/book/availability/json for free slots based on 'how often' for 4 months ahead

Backend method is called right after filling contacts data because next we are showing calendar table with free slots. 

###### Under which circumstances is it necessary to recall the function?

At homejoy.com request with free slots and pricing made only once and be recalled after some time to update data.

###### Roughly sketch out the data model (table structure) of this particular part of the application

I have not created authentication methods so User table here is only to store user information that may be duplicated.

Because of aim of the task is to create an API to find free slots and to book them i have not created a method to calculate price for each slots. In that case i would create a settings file (in yml for example) where i would store all the costs for supplies options, for 'how often' parameter etc.

I did not take into consideration time for team to rest and to transfer from one place to another. All settings are stored in [slot.rb](https://github.com/developer88/cleanmythings/blob/master/app/models/slot.rb "slot.rb"). 

Look at [schema.rb](https://github.com/developer88/cleanmythings/blob/master/db/schema.rb "schema.rb") for more details.

At first i wanted to create slots in table with step of 30 minutes, but then i reakize that it is a bad idea to store empty rows in DB so i finally decided to store only filled slots.

Because of each slot may have different start time and length i use GAP constant to check if next slot is in +- GAP interval + i round each start_at param to hours.

I use SQLite so no indexes were created.

###### Create API

* Look at [slots_controller.rb](https://github.com/developer88/cleanmythings/blob/master/app/controllers/slots_controller.rb "slots_controller.rb") for main API methods.
* Look at [slots_controller_spec.rb](https://github.com/developer88/cleanmythings/blob/master/spec/controllers/slots_controller_spec.rb "slots_controller_spec.rb") for main API methods specs.

###### Overall

I think i have chosen too complicated way to check for slots available :( 
