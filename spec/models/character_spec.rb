require 'rails_helper'

RSpec.describe Character, type: :model do
  describe 'relationships' do
    it { should belong_to(:story) }
    it { should have_many(:character_events) }
    it { should have_many(:events).through(:character_events) }
    it { should have_many(:character_locations) }
    it { should have_many(:locations).through(:character_locations) }
    it { should have_many(:items) }
    it { should have_many(:mission_characters) }
    it { should have_many(:missions).through(:mission_characters) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:role) }
  end
end
