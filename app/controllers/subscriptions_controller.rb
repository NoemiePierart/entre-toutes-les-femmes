class SubscriptionsController < ApplicationController
  skip_before_action :authenticate_user!

  def create
    email = params[:email].to_s.strip

    unless email.match?(/\A[^@\s]+@[^@\s]+\.[^@\s]+\z/)
      return redirect_back fallback_location: root_path, alert: "Adresse e-mail invalide."
    end

    BrevoClient.new.subscribe(email)
    redirect_back fallback_location: root_path, notice: "Merci ! Vous recevrez bientôt la prochaine lettre."
  rescue KeyError
    redirect_back fallback_location: root_path, alert: "L'abonnement n'est pas encore configuré (BREVO_LIST_ID manquant)."
  rescue => e
    Rails.logger.error "Brevo subscription error: #{e.message}"
    redirect_back fallback_location: root_path, alert: "Une erreur est survenue. Veuillez réessayer."
  end
end
