class Item < ApplicationRecord
  belongs_to :character

  validates :name, presence: true
  validates :description, presence: true
  validates :type, presence: true
end
