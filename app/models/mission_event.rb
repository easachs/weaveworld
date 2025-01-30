class MissionEvent < ApplicationRecord
  belongs_to :mission
  belongs_to :event

  validates :mission_id, presence: true
  validates :event_id, presence: true
end
