class ActivityReportsController < ApplicationController
  def show
    @notebook = current_user.notebooks.find(params[:notebook_id])
    @daily_note_counts = @notebook.daily_note_counts
  end
end
