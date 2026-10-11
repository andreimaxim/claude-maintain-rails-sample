class Note < ApplicationRecord
  HIGHLIGHT_COLORS = %w[ yellow green blue pink ]
  MAXIMUM_ATTACHMENT_SIZE = 1.megabyte

  belongs_to :notebook
  belongs_to :import, optional: true
  belongs_to :citation, optional: true, foreign_key: :citation_doi, validate: true
  has_rich_text :body

  enum status: { draft: 0, ready: 1 }, _prefix: true

  serialize :tags, JSON
  store_accessor :settings, :color
  alias_attribute :highlight_color, :color

  validates :title, presence: true
  validates :color, inclusion: { in: HIGHLIGHT_COLORS }, allow_blank: true
  validates :reminder_epoch, numericality: { only_integer: true, greater_than: 0, less_than: 10_000_000_000 }, allow_nil: true
  validate :attachments_are_small

  scope :newest_first, -> { order(created_at: :desc, id: :desc) }
  scope :titled_like, ->(query) { where("notes.title ILIKE ?", "%#{sanitize_sql_like(query)}%") }

  def tag_list
    tags.join(", ")
  end

  def tag_list=(list)
    self.tags = list.to_s.split(",").map(&:strip).reject(&:blank?).uniq
  end

  private
    def attachments_are_small
      if body.body&.attachables.to_a.grep(ActiveStorage::Blob).any? { |blob| blob.byte_size > MAXIMUM_ATTACHMENT_SIZE }
        errors.add(:body, "attachments must be #{ActiveSupport::NumberHelper.number_to_human_size(MAXIMUM_ATTACHMENT_SIZE)} or smaller")
      end
    end
end
