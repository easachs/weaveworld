class Location < ApplicationRecord
  belongs_to :story
  has_many :character_locations, dependent: :destroy
  has_many :characters, through: :character_locations
  has_many :location_events, dependent: :destroy
  has_many :events, through: :location_events
  has_many :mission_locations
  has_many :missions, through: :mission_locations

  validates :name, presence: true
  validates :description, presence: true
  validates :category, presence: true
end
