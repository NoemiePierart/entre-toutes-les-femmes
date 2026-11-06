class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!

  before_action :verify_secret

  def brevo
    payload     = JSON.parse(request.body.read)
    campaign_id = payload["campaign_id"].to_i

    return head :ok if campaign_id.zero?

    # The job records the event once the letter is imported, so a failed import
    # is retried on Brevo's next call
    BrevoSyncJob.perform_later(campaign_id) unless ProcessedBrevoEvent.exists?(campaign_id: campaign_id)
    head :ok
  rescue JSON::ParserError
    head :bad_request
  end

  private

  def verify_secret
    # Refuses everything when the secret is missing, rather than accepting everything
    expected = ENV["BREVO_WEBHOOK_SECRET"].to_s
    head :unauthorized if expected.empty? || !ActiveSupport::SecurityUtils.secure_compare(params[:token].to_s, expected)
  end
end
