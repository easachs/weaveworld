require 'rails_helper'

RSpec.describe Mission, type: :model do
  describe 'relationships' do
    it { should belong_to(:story) }
    it { should have_many(:mission_characters) }
    it { should have_many(:characters).through(:mission_characters) }
    it { should have_many(:mission_events) }
    it { should have_many(:events).through(:mission_events) }
    it { should have_many(:mission_locations) }
    it { should have_many(:locations).through(:mission_locations) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:status) }
  end
end
