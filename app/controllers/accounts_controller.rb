class AccountsController < ApplicationController
  def edit
  end

  def update
    if current_user.update(account_params)
      redirect_to edit_account_path, status: :see_other, notice: "Account settings saved."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def account_params
      params.require(:user).permit(:time_zone)
    end
end
