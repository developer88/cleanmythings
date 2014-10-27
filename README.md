# Clean My Things

Used RoR and SQLite:
*  First cause this is my favorite framework on ruby.
*  Second cause it fits well for that little task.


## Task

###### Explain shortly how you will do the following (make appropriate drawings or documentation):
###### Identify all necessary parameter that are transmitted to the backend end-point, in order to receive all available time slots 
###### Clarify in which step the backend function should be called
###### Under which circumstances is it necessary to recall the function?



###### Roughly sketch out the data model (table structure) of this particular part of the application

I have not created authentication methods so User table here is only to store user information that may be duplicated.

Look at [schema.rb](https://github.com/developer88/cleanmythings/blob/master/db/schema.rb "schema.rb") for more details.


###### Create API

* Look at [slots_controller.rb](https://github.com/developer88/cleanmythings/blob/master/app/controllers/slots_controller.rb "slots_controller.rb") for main API methods.
* Look at [slots_controller_spec.rb](https://github.com/developer88/cleanmythings/blob/master/spec/controllers/slots_controller_spec.rb "slots_controller_spec.rb") for main API methods specs.
