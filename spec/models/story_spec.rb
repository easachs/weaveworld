require 'rails_helper'

RSpec.describe Story, type: :model do
  describe 'relationships' do
    it { should belong_to(:user) }
    it { should have_many(:characters) }
    it { should have_many(:events) }
    it { should have_many(:facts) }
    it { should have_many(:locations) }
    it { should have_many(:missions) }
  end

  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:genre) }
    it { should validate_presence_of(:overview) }
  end
end
