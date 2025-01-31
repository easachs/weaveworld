class Character < ApplicationRecord
  belongs_to :story
  has_many :character_events, dependent: :destroy
  has_many :events, through: :character_events
  has_many :character_locations, dependent: :destroy
  has_many :locations, through: :character_locations
  has_many :items, dependent: :destroy
  has_many :mission_characters
  has_many :missions, through: :mission_characters

  validates :name, presence: true
  validates :description, presence: true
  validates :role, presence: true
end
