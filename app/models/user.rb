class User < ApplicationRecord
  has_secure_password

  has_many :notebooks, dependent: :destroy
  has_many :notes, through: :notebooks

  before_validation { self.email = email.to_s.strip.downcase }

  validates :email, presence: true, uniqueness: true

  def self.authenticate(email, password)
    find_by(email: email.to_s.strip.downcase)&.authenticate(password)
  end
end
