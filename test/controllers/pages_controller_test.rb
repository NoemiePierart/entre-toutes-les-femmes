require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "about page is public" do
    get about_url
    assert_response :success
    assert_select "h1", "À propos"
  end

  test "contact page is public" do
    get contact_url
    assert_response :success
    assert_select "a[href='mailto:bonjour@entretouteslesfemmes.fr']"
    assert_select ".footer-subscribe-card-wrap", count: 0
  end
end
