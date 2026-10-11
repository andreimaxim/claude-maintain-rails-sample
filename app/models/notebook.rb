class Notebook < ApplicationRecord
  belongs_to :user
  has_many :notes, dependent: :destroy
  has_many :imports, dependent: :destroy
  has_many :exports, dependent: :destroy

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

  # Queues a Markdown export. The export is saved before its job is queued, so
  # the worker can always load it, and removed again if Redis refuses the job.
  def request_export
    export = exports.create!
    export.update!(job_id: ExportJob.perform_async(export.id, { format: "markdown" }))
    export
  rescue Redis::BaseError
    export&.destroy
    raise
  end

  private
    def assign_slug
      self.slug = name.to_s.parameterize.presence || "notebook"
    end
end
