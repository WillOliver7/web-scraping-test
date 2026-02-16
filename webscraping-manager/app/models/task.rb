class Task < ApplicationRecord
  validates :url, :user_id, presence: true
  has_many :quotes
end
