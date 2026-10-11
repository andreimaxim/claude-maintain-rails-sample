class ReminderPostponementsController < ApplicationController
  def create
    note = current_user.notes.find(params[:note_id])

    notice = note.postpone_reminder ? "Reminder postponed a day." : "This note has no scheduled reminder to postpone."
    redirect_to note_path(note), status: :see_other, notice: notice
  end
end
