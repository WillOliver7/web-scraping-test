class User < ApplicationRecord
  has_secure_password
  validates :email, presence: true, uniqueness: true
  has_many :tasks, dependent: :destroy
  has_many :quotes, dependent: :destroy
end
