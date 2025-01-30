require 'rails_helper'

RSpec.describe Event, type: :model do
  describe 'relationships' do
    it { should belong_to(:story) }
    it { should have_many(:character_events) }
    it { should have_many(:characters).through(:character_events) }
    it { should have_many(:location_events) }
    it { should have_many(:locations).through(:location_events) }
    it { should have_many(:mission_events) }
    it { should have_many(:missions).through(:mission_events) }
  end

  describe 'validations' do
    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:short) }
    it { should validate_presence_of(:category) }
  end
end
