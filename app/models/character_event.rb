class CharacterEvent < ApplicationRecord
  belongs_to :character
  belongs_to :event

  validates :character_id, presence: true
  validates :event_id, presence: true
end
