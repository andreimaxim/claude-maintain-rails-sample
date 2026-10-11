# A Markdown file of one notebook's notes, written by ExportJob. The reader can
# cancel it while it is queued or working; the worker checks between notes and
# stops. A completed file can be downloaded until it expires.
class Export < ApplicationRecord
  AVAILABLE_FOR = 24.hours

  belongs_to :notebook
  has_one_attached :file

  enum :status, { queued: 0, working: 1, completed: 2, cancelled: 3 }

  scope :newest_first, -> { order(created_at: :desc, id: :desc) }

  def cancellable?
    queued? || working?
  end

  # Cancels a queued or working export. Returns whether it was cancelled.
  def cancel
    with_lock do
      if cancellable?
        update!(status: :cancelled)
      else
        false
      end
    end
  end

  # Writes the notebook's notes, oldest first, under its export heading. Progress
  # is saved after each note. A cancelled export stops before the next note and
  # keeps no file.
  def generate
    notes = notebook.notes.with_rich_text_body.order(:created_at, :id).to_a
    return unless start(notes.size)

    fragments = ["# #{notebook.export_heading || notebook.name}\n"]
    notes.each_with_index do |note, index|
      fragments << markdown_for(note)
      return unless record_progress(index + 1)
    end

    finish(fragments.sum)
  end

  # The authoritative check for downloading the file.
  def downloadable?
    completed? && expires_at.future?
  end

  private
    # A retried job starts again from the first note.
    def start(total)
      with_lock do
        update!(status: :working, processed_notes_count: 0, total_notes_count: total) if cancellable?
      end
    end

    def record_progress(count)
      with_lock do
        update!(processed_notes_count: count) unless cancelled?
      end
    end

    # The file is stored before the export is marked completed, so a completed
    # export always has one.
    def finish(markdown)
      blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new(markdown),
        filename: "#{notebook.slug}.md", content_type: "text/markdown")

      completed = with_lock do
        update!(file: blob, status: :completed, expires_at: AVAILABLE_FOR.from_now) unless cancelled?
      end

      blob.purge unless completed
    end

    def markdown_for(note)
      body = note.body.to_plain_text.strip
      markdown = "\n## #{note.title.squish}\n"
      markdown += "\n#{body}\n" if body.present?
      markdown
    end
end
