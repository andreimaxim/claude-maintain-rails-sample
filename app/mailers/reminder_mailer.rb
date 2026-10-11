class ReminderMailer < ApplicationMailer
  def note_reminder
    @note = params[:note]
    mail to: @note.notebook.user.email, subject: "Reminder: #{@note.title}"
  end
end
