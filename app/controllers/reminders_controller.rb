class RemindersController < ApplicationController
  # Schedules a reminder at the date and time the reader entered, in their time
  # zone, or at the note's stored reminder time when none is entered.
  def create
    @note = current_user.notes.find(params[:note_id])
    scheduled = if params[:reminder]
      @note.schedule_reminder(current_user.local_time(params[:reminder][:at])&.to_i)
    else
      @note.schedule_reminder
    end

    if scheduled
      redirect_to note_path(@note), status: :see_other, notice: "Reminder scheduled."
    else
      render "notes/show", status: :unprocessable_entity
    end
  end
end
