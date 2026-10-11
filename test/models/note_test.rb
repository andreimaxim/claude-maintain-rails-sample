require "test_helper"

class NoteTest < ActiveSupport::TestCase
  test "newest first breaks created_at ties by descending id" do
    created_at = Time.utc(2026, 9, 10, 12)
    first = notebooks(:novels).notes.create!(title: "First", created_at: created_at)
    second = notebooks(:novels).notes.create!(title: "Second", created_at: created_at)

    assert_equal [second, first, notes(:middlemarch)], notebooks(:novels).notes.newest_first.to_a
  end

  test "title search is case-insensitive and treats wildcards literally" do
    discount = notebooks(:essays).notes.create!(title: "Notes at 100% attention")

    assert_includes Note.titled_like("MIDDLEMARCH"), notes(:middlemarch)
    assert_not_includes Note.titled_like("MIDDLEMARCH"), notes(:montaigne)
    assert_equal [discount], Note.titled_like("0%").to_a
  end

  test "rejects rich text attachments larger than one megabyte" do
    large = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("x" * (1.megabyte + 1)), filename: "scan.pdf", content_type: "application/pdf")
    note = notebooks(:novels).notes.new(title: "Scanned chapter",
      body: %(<action-text-attachment sgid="#{large.attachable_sgid}"></action-text-attachment>))

    assert_not note.valid?
    assert_equal ["attachments must be 1 MB or smaller"], note.errors[:body]
  end
end
