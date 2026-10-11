class Notebook < ApplicationRecord
  belongs_to :user
  has_many :notes, dependent: :destroy
  has_many :imports, dependent: :destroy

  serialize :preferences
  attr_readonly :slug

  before_validation :assign_slug, on: :create

  validates :name, presence: true

  def export_heading
    preferences.to_h["export_heading"]
  end

  def export_heading=(heading)
    self.preferences = preferences.to_h.merge("export_heading" => heading.to_s.strip.presence).compact
  end

  private
    def assign_slug
      self.slug = name.to_s.parameterize.presence || "notebook"
    end
end
