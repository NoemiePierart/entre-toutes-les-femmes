require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "about page is public" do
    get about_url
    assert_response :success
    assert_select "h1", "Qui suis-je\u00A0?"
  end

  test "old about URL redirects to the author page" do
    get "/a-propos"
    assert_redirected_to "/auteur"
  end

  test "home shows an arch but no band for a theme without posts" do
    Theme.create!(name: "Pensées diverses")

    get root_url

    assert_response :success
    assert_select ".home-arch-name", "Pensées diverses"
    assert_select ".home-rubrique", count: 0
  end

  test "contact page is public" do
    get contact_url
    assert_response :success
    assert_select "a[href='mailto:bonjour@entretouteslesfemmes.fr']"
    assert_select ".footer-call", count: 2
  end
end
