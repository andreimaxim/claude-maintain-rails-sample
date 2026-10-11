class NoteReminderJob < ApplicationJob
  queue_as :default

  # The note may have been deleted while its reminder was scheduled.
  discard_on ActiveJob::DeserializationError

  def perform(note)
    note.send_reminder(job_id)
  end
end
