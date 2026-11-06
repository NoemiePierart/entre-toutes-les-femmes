require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = User.create!(email: "admin@example.com", password: "password123", admin: true)
    @reader = User.create!(email: "lectrice@example.com", password: "password123")
    @post = Post.create!(
      title: "Une œuvre à savourer",
      content: "<p>Un tableau à regarder longuement.</p>",
      theme: Theme.create!(name: "Une œuvre d'art à savourer"),
      newsletter: Newsletter.create!(number: 12, published_on: Date.new(2024, 3, 3)),
      user: @admin
    )
  end

  test "index redirects to the homepage" do
    get posts_url

    assert_redirected_to root_url
  end

  test "show is public" do
    get post_url(@post)

    assert_response :success
    assert_match "Un tableau à regarder longuement.", response.body
  end

  test "new and edit ask visitors to sign in" do
    get new_post_url
    assert_redirected_to new_user_session_url

    get edit_post_url(@post)
    assert_redirected_to new_user_session_url
  end

  test "new and edit are refused to readers who are not admins" do
    sign_in @reader

    get new_post_url
    assert_redirected_to root_url
    assert_equal "Accès non autorisé.", flash[:alert]

    get edit_post_url(@post)
    assert_redirected_to root_url
  end

  test "new and edit are available to admins" do
    sign_in @admin

    get new_post_url
    assert_response :success

    get edit_post_url(@post)
    assert_response :success
  end
end
