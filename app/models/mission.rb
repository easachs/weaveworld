class Mission < ApplicationRecord
  belongs_to :story
  has_many :mission_characters
  has_many :characters, through: :mission_characters
  has_many :mission_events
  has_many :events, through: :mission_events
  has_many :mission_locations
  has_many :locations, through: :mission_locations

  validates :name, presence: true
  validates :description, presence: true
  validates :status, presence: true
end
