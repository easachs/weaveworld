class Story < ApplicationRecord
  belongs_to :user
  has_many :characters, dependent: :destroy
  has_many :events, dependent: :destroy
  has_many :facts, dependent: :destroy
  has_many :locations, dependent: :destroy
  has_many :missions, dependent: :destroy

  validates :title, presence: true
  validates :genre, presence: true
  validates :overview, presence: true
end
