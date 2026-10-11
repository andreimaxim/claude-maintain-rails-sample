class ApplicationController < ActionController::Base
  before_action :require_sign_in

  helper_method :current_user

  private
    def current_user
      @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
    end

    def require_sign_in
      redirect_to new_session_path unless current_user
    end

    def sign_in(user)
      reset_session
      session[:user_id] = user.id
    end
end
