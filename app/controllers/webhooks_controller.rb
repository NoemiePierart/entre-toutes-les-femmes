class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!

  before_action :verify_secret

  def brevo
    payload     = JSON.parse(request.body.read)
    campaign_id = payload["campaign_id"].to_i

    return head :ok if campaign_id.zero?

    ProcessedBrevoEvent.create!(campaign_id: campaign_id)
    BrevoSyncJob.perform_later(campaign_id)
    head :ok
  rescue ActiveRecord::RecordNotUnique
    head :ok
  rescue JSON::ParserError
    head :bad_request
  end

  private

  def verify_secret
    expected = ENV["BREVO_WEBHOOK_SECRET"]
    return if expected.blank?
    head :unauthorized unless ActiveSupport::SecurityUtils.secure_compare(params[:token].to_s, expected)
  end
end
