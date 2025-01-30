require 'rails_helper'

RSpec.describe Location, type: :model do
  describe 'relationships' do
    it { should belong_to(:story) }
    it { should have_many(:character_locations) }
    it { should have_many(:characters).through(:character_locations) }
    it { should have_many(:location_events) }
    it { should have_many(:events).through(:location_events) }
    it { should have_many(:mission_locations) }
    it { should have_many(:missions).through(:mission_locations) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:type) }
  end
end
