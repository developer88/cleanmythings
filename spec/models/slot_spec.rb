require 'spec_helper'
require 'rails_helper'

RSpec.describe Slot, type: :model do

  it { should validate_presence_of(:supplies_by_owner) }
  it { should validate_presence_of(:date) }
  it { should validate_presence_of(:start_at) }

  it { should validate_numericality_of(:bathrooms).only_integer.is_greater_than_or_equal_to(1).is_less_than_or_equal_to(5) }
  it { should validate_numericality_of(:bedrooms).only_integer.is_greater_than_or_equal_to(0).is_less_than_or_equal_to(5) }
  it { should validate_numericality_of(:how_often).only_integer.is_greater_than_or_equal_to(0).is_less_than_or_equal_to(4) }

  it { should belong_to(:slot_user) }

end