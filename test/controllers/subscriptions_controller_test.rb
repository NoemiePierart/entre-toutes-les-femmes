require "test_helper"

class SubscriptionsControllerTest < ActionDispatch::IntegrationTest
  test "invalid email is reported inside the block" do
    post subscribe_url, params: { email: "pas-une-adresse" }, as: :turbo_stream

    assert_response :unprocessable_entity
    assert_match 'target="footer-subscribe"', response.body
    assert_match "Adresse e-mail invalide.", response.body
    assert_match 'value="pas-une-adresse"', response.body
  end

  test "successful subscription replaces the form with a thank-you" do
    subscribed = []
    with_fake_brevo(subscribed) do
      post subscribe_url, params: { email: "lectrice@example.com" }, as: :turbo_stream
    end

    assert_response :success
    assert_match "Merci ! Vous recevrez bientôt la prochaine lettre.", response.body
    assert_no_match "footer-subscribe-form", response.body
    assert_equal [ "lectrice@example.com" ], subscribed
  end

  test "plain form submission still redirects with a flash" do
    post subscribe_url, params: { email: "pas-une-adresse" }

    assert_redirected_to root_url
    assert_equal "Adresse e-mail invalide.", flash[:alert]
  end

  private

  # Stands in for BrevoClient so no request leaves the test
  def with_fake_brevo(subscribed)
    fake = Object.new
    fake.define_singleton_method(:subscribe) { |email| subscribed << email }
    BrevoClient.define_singleton_method(:new) { |*| fake }
    yield
  ensure
    BrevoClient.singleton_class.remove_method(:new)
  end
end
