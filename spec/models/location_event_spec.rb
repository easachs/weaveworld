require 'rails_helper'

RSpec.describe LocationEvent, type: :model do
  describe 'relationships' do
    it { should belong_to(:location) }
    it { should belong_to(:event) }
  end

  describe 'validations' do
    it { should validate_presence_of(:location_id) }
    it { should validate_presence_of(:event_id) }
  end
end
