require 'spec_helper'
require 'rails_helper'

RSpec.describe User, type: :model do

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:email) }
  it { should validate_presence_of(:zip) }
  it { should validate_presence_of(:phone) }
  it { should validate_presence_of(:address) }

  it { should have_many(:slots) }

end