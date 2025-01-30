require 'rails_helper'

RSpec.describe CharacterLocation, type: :model do
  describe 'relationships' do
    it { should belong_to(:character) }
    it { should belong_to(:location) }
  end

  describe 'validations' do
    it { should validate_presence_of(:character_id) }
    it { should validate_presence_of(:location_id) }
  end
end
