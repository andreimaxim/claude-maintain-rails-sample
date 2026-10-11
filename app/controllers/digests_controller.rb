class DigestsController < ApplicationController
  def create
    notice = if current_user.request_digest
      "Today's reading digest is on its way."
    else
      "You have already requested today's reading digest."
    end

    redirect_to notes_path, status: :see_other, notice: notice
  end
end
