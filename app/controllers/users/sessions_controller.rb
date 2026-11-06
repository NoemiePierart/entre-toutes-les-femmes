module Users
  class SessionsController < Devise::SessionsController
    # Slows down password guessing on the admin account
    rate_limit to: 10, within: 15.minutes, only: :create, with: -> {
      redirect_to new_user_session_path, alert: "Trop de tentatives de connexion. Réessayez dans quelques minutes."
    }
  end
end
