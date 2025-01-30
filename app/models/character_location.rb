class CharacterLocation < ApplicationRecord
  belongs_to :character
  belongs_to :location

  validates :character_id, presence: true
  validates :location_id, presence: true
end
