require "test_helper"

class ExportTest < ActiveSupport::TestCase
  test "a cancellation recorded while the worker is running stops it before the next note" do
    notebook = notebooks(:novels)
    notebook.notes.create!(title: "Adam Bede", created_at: Time.utc(2026, 9, 5))
    notebook.notes.create!(title: "Silas Marner", created_at: Time.utc(2026, 9, 6))
    export = notebook.exports.create!

    # The reader cancels just after the worker records its first note.
    cancel = ->(*, payload) { Export.find(export.id).cancel if payload[:sql].start_with?('UPDATE "exports" SET "processed_notes_count"') }

    uploads = 0
    assert_no_difference -> { ActiveStorage::Blob.count } do
      ActiveSupport::Notifications.subscribed(->(*) { uploads += 1 }, "service_upload.active_storage") do
        ActiveSupport::Notifications.subscribed(cancel, "sql.active_record") { export.generate }
      end
    end
    assert_equal 0, uploads, "the worker stops instead of writing and discarding a file"

    export.reload
    assert export.cancelled?
    assert_equal [1, 3], [export.processed_notes_count, export.total_notes_count]
    assert_not export.file.attached?
  end
end
