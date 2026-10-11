class SessionsController < ApplicationController
  skip_before_action :require_sign_in, only: [:new, :create]

  def new
  end

  def create
    if user = User.authenticate(params[:email], params[:password])
      sign_in user
      redirect_to notes_path
    else
      flash.now[:alert] = "Email or password is incorrect."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to new_session_path, status: :see_other, notice: "Signed out."
  end
end
