require 'rails_helper'

RSpec.describe CharacterEvent, type: :model do
  describe 'relationships' do
    it { should belong_to(:character) }
    it { should belong_to(:event) }
  end

  describe 'validations' do
    it { should validate_presence_of(:character_id) }
    it { should validate_presence_of(:event_id) }
  end
end
