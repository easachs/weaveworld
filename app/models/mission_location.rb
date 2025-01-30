class MissionLocation < ApplicationRecord
  belongs_to :mission
  belongs_to :location

  validates :mission_id, presence: true
  validates :location_id, presence: true
  validates :role, presence: true
end
