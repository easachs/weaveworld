require 'rails_helper'

RSpec.describe MissionEvent, type: :model do
  describe 'relationships' do
    it { should belong_to(:mission) }
    it { should belong_to(:event) }
  end

  describe 'validations' do
    it { should validate_presence_of(:mission_id) }
    it { should validate_presence_of(:event_id) }
  end
end
