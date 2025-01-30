class Event < ApplicationRecord
  belongs_to :story
  has_many :character_events
  has_many :characters, through: :character_events
  has_many :location_events
  has_many :locations, through: :location_events
  has_many :mission_events
  has_many :missions, through: :mission_events

  validates :description, presence: true
  validates :short, presence: true
  validates :type, presence: true
end
