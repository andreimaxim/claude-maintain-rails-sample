require "test_helper"

class ActivityReportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:reader)
  end

  test "a notebook's notes are counted by UTC creation date, newest first" do
    # Bucharest is ahead of UTC, so the 23:30 note is on 11 October there.
    users(:reader).update!(time_zone: "Bucharest")
    notebook = notebooks(:novels)
    notebook.notes.create!(title: "Adam Bede", status: :ready, created_at: Time.utc(2026, 10, 10, 23, 30))
    notebook.notes.create!(title: "Romola", created_at: Time.utc(2026, 10, 11, 0, 30))
    notebook.notes.create!(title: "Silas Marner", status: :ready, created_at: Time.utc(2026, 10, 11, 18))
    notebooks(:essays).notes.create!(title: "Of experience", created_at: Time.utc(2026, 10, 10, 9))
    notebooks(:other_research).notes.create!(title: "Felix Holt", created_at: Time.utc(2026, 10, 11, 9))

    get notebook_activity_report_path(notebook)

    assert_response :success
    rows = css_select(".activity-report tbody tr").map { |row| row.css("td").map { |cell| cell.text.strip } }
    assert_equal [["11 October 2026", "2"], ["10 October 2026", "1"], ["1 September 2026", "1"]], rows
    assert_select ".activity-report time[datetime=?]", "2026-10-11"
    assert_select "p.empty", count: 0
  end

  test "an empty notebook says so, and another reader's notebook is not found" do
    notebook = users(:reader).notebooks.create!(name: "Poetry")

    get notebook_activity_report_path(notebook)
    assert_response :success
    assert_select ".activity-report", count: 0
    assert_select "p.empty", "This notebook has no notes yet."

    assert_raises(ActiveRecord::RecordNotFound) { get notebook_activity_report_path(notebooks(:other_research)) }
  end
end
