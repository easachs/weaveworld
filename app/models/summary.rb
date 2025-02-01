class Summary < ApplicationRecord
  belongs_to :story
  
  validates :text, presence: true
end 