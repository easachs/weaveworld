class LocationEvent < ApplicationRecord
  belongs_to :location
  belongs_to :event

  validates :location_id, presence: true
  validates :event_id, presence: true
end
