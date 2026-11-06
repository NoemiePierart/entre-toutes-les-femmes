class SubscriptionsController < ApplicationController
  skip_before_action :authenticate_user!

  # Keeps anyone from pouring addresses into the Brevo list
  rate_limit to: 5, within: 10.minutes, only: :create, with: -> {
    respond_with(:alert, "Trop de tentatives. Réessayez dans quelques minutes.")
  }

  def create
    @email = params[:email].to_s.strip

    return respond_with(:alert, "Adresse e-mail invalide.") unless @email.match?(/\A[^@\s]+@[^@\s]+\.[^@\s]+\z/)

    BrevoClient.new.subscribe(@email)
    respond_with(:ok, "Merci ! Vous recevrez bientôt la prochaine lettre.")
  rescue KeyError
    respond_with(:alert, "L'abonnement n'est pas encore configuré (BREVO_LIST_ID manquant).")
  rescue => e
    Rails.logger.error "Brevo subscription error: #{e.message}"
    respond_with(:alert, "Une erreur est survenue. Veuillez réessayer.")
  end

  private

  # Turbo replaces the form with the answer in place; plain requests keep the flash
  def respond_with(status, message)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: answer_stream(status, message), status: status == :ok ? :ok : :unprocessable_entity
      end
      format.html { redirect_back fallback_location: root_path, (status == :ok ? :notice : :alert) => message }
    end
  end

  def answer_stream(status, message)
    locals = { status: status, message: message, email: @email }
    turbo_stream.replace("footer-subscribe", partial: "shared/subscribe_form", locals: locals)
  end
end
