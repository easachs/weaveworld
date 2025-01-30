require 'rails_helper'

RSpec.describe MissionCharacter, type: :model do
  describe 'relationships' do
    it { should belong_to(:mission) }
    it { should belong_to(:character) }
  end

  describe 'validations' do
    it { should validate_presence_of(:mission_id) }
    it { should validate_presence_of(:character_id) }
    it { should validate_presence_of(:role) }
  end
end
