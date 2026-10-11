require "test_helper"

class RemindersControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:reader) }

  test "a reader schedules a reminder in their time zone and is emailed once it is due" do
    users(:reader).update!(time_zone: "Eastern Time (US & Canada)")
    note = notes(:montaigne)

    post note_reminder_path(note), params: { reminder: { at: "2026-10-31T09:00" } }
    assert_redirected_to note_path(note)

    nine_eastern = Time.utc(2026, 10, 31, 13).to_i
    job = enqueued_jobs.sole
    assert_equal [NoteReminderJob, nine_eastern], job.values_at(:job, :at)
    assert_equal nine_eastern, note.reload.reminder_epoch

    follow_redirect!
    assert_select "#reminder", /Scheduled\s+for\s+Sat 31 Oct 2026, 09:00 \(UTC-04:00\)/
    # Daylight saving time ends before the next day; the preview keeps the offset.
    assert_select "#next_day_reminder time[datetime=?]", "2026-11-01T09:00:00-04:00"

    perform_enqueued_jobs
    mail = ActionMailer::Base.deliveries.sole
    assert_equal ["reader@example.com"], mail.to
    assert_equal "Reminder: Montaigne on friendship", mail.subject
    assert_includes mail.body.to_s, %(about "Montaigne on friendship" in Essays at Sat 31 Oct 2026, 09:00 (UTC-04:00))
    assert_includes mail.body.to_s, note_url(note)

    # A repeated delivery of the same job sends nothing more.
    assert_no_emails { note.reload.send_reminder(job["job_id"]) }

    get note_path(note)
    assert_select "#reminder", /Sent\.\s+The reminder for\s+Sat 31 Oct 2026, 09:00/
    assert_select "#reminder form[action=?]", note_reminder_postponement_path(note), count: 0
  end

  test "an imported reminder is scheduled at its exact time, and postponing replaces it" do
    note = notes(:montaigne)
    note.update!(reminder_epoch: 1_793_451_617)

    get note_path(note)
    assert_select "#reminder", /Imported for\s+Sat 31 Oct 2026, 13:00 \(UTC\+00:00\)/

    post note_reminder_path(note)
    assert_redirected_to note_path(note)
    assert_equal 1_793_451_617, enqueued_jobs.sole[:at]

    post note_reminder_postponement_path(note)
    assert_redirected_to note_path(note)
    assert_equal "Reminder postponed a day.", flash[:notice]
    assert_equal [1_793_451_617, 1_793_538_017], enqueued_jobs.map { |job| job[:at] }
    assert_equal 1_793_538_017, note.reload.reminder_epoch

    # Both jobs run, but only the reminder that replaced the first one is sent.
    assert_emails(1) { perform_enqueued_jobs }
    assert_includes ActionMailer::Base.deliveries.sole.body.to_s, "Sun 1 Nov 2026, 13:00"
  end

  test "a reminder needs a time, and another reader's notes cannot be reminded" do
    note = notes(:montaigne)

    post note_reminder_path(note), params: { reminder: { at: "" } }
    assert_response :unprocessable_entity
    assert_select "#reminder .errors", /Choose a date and time for the reminder/

    other_note = notes(:other_secret)
    other_note.update!(reminder_epoch: 1_793_451_617)
    assert_raises(ActiveRecord::RecordNotFound) { post note_reminder_path(other_note) }
    assert_raises(ActiveRecord::RecordNotFound) { post note_reminder_postponement_path(other_note) }

    assert_no_enqueued_jobs
    assert_nil note.reload.reminder_epoch
    assert_nil other_note.reload.reminder_job_id
  end
end
