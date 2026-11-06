require "test_helper"

class WebhooksControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  test "a new campaign is queued without being marked as processed" do
    assert_enqueued_with(job: BrevoSyncJob, args: [ 4242 ]) do
      post_webhook campaign_id: 4242
    end

    assert_response :success
    assert_not ProcessedBrevoEvent.exists?(campaign_id: 4242)
  end

  test "an already imported campaign is not queued again" do
    ProcessedBrevoEvent.create!(campaign_id: 4243)

    assert_no_enqueued_jobs do
      post_webhook campaign_id: 4243
    end
    assert_response :success
  end

  test "a wrong token is refused" do
    skip "BREVO_WEBHOOK_SECRET non défini : le webhook accepte tout" if ENV["BREVO_WEBHOOK_SECRET"].blank?

    assert_no_enqueued_jobs do
      post brevo_webhook_url(token: "mauvais"), params: { campaign_id: 4244 }.to_json,
        headers: { "CONTENT_TYPE" => "application/json" }
    end
    assert_response :unauthorized
  end

  private

  def post_webhook(campaign_id:)
    post brevo_webhook_url(token: ENV["BREVO_WEBHOOK_SECRET"].to_s),
      params: { campaign_id: campaign_id }.to_json,
      headers: { "CONTENT_TYPE" => "application/json" }
  end
end
