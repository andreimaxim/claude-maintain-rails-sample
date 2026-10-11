class Note < ApplicationRecord
  belongs_to :notebook

  enum status: { draft: 0, ready: 1 }, _prefix: true

  validates :title, presence: true

  scope :newest_first, -> { order(created_at: :desc, id: :desc) }
  scope :titled_like, ->(query) { where("notes.title ILIKE ?", "%#{sanitize_sql_like(query)}%") }
end
