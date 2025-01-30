require 'rails_helper'

RSpec.describe Fact, type: :model do
  describe 'relationships' do
    it { should belong_to(:story) }
  end

  describe 'validations' do
    it { should validate_presence_of(:text) }
  end
end
