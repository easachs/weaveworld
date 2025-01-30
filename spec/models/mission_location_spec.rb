require 'rails_helper'

RSpec.describe MissionLocation, type: :model do
  describe 'relationships' do
    it { should belong_to(:mission) }
    it { should belong_to(:location) }
  end

  describe 'validations' do
    it { should validate_presence_of(:mission_id) }
    it { should validate_presence_of(:location_id) }
    it { should validate_presence_of(:role) }
  end
end
