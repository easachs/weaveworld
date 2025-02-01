require 'rails_helper'

RSpec.describe Story, type: :model do
  describe 'relationships' do
    it { should belong_to(:user) }
    it { should have_many(:characters).dependent(:destroy) }
    it { should have_many(:events).dependent(:destroy) }
    it { should have_many(:facts).dependent(:destroy) }
    it { should have_many(:locations).dependent(:destroy) }
    it { should have_many(:missions).dependent(:destroy) }
    it { should have_many(:summaries).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:genre) }
    it { should validate_presence_of(:overview) }
  end
end
