class MissionCharacter < ApplicationRecord
  belongs_to :mission
  belongs_to :character

  validates :mission_id, presence: true
  validates :character_id, presence: true
  validates :role, presence: true
end
