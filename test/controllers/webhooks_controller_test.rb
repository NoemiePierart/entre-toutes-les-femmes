require "test_helper"

class WebhooksControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @previous_secret = ENV["BREVO_WEBHOOK_SECRET"]
    ENV["BREVO_WEBHOOK_SECRET"] = "secret-de-test"
  end

  teardown { ENV["BREVO_WEBHOOK_SECRET"] = @previous_secret }

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
    assert_no_enqueued_jobs do
      post brevo_webhook_url(token: "mauvais"), params: { campaign_id: 4244 }.to_json,
        headers: { "CONTENT_TYPE" => "application/json" }
    end
    assert_response :unauthorized
  end

  test "everything is refused when no secret is configured" do
    ENV["BREVO_WEBHOOK_SECRET"] = nil

    assert_no_enqueued_jobs do
      post brevo_webhook_url(token: ""), params: { campaign_id: 4245 }.to_json,
        headers: { "CONTENT_TYPE" => "application/json" }
    end
    assert_response :unauthorized
  end

  private

  def post_webhook(campaign_id:)
    post brevo_webhook_url(token: "secret-de-test"),
      params: { campaign_id: campaign_id }.to_json,
      headers: { "CONTENT_TYPE" => "application/json" }
  end
end
