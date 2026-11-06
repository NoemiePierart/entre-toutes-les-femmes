require "test_helper"

class UsersAccessTest < ActionDispatch::IntegrationTest
  test "public sign-up is closed" do
    get "/users/sign_up"
    assert_response :not_found
  end

  test "the sign-in page no longer offers to create an account" do
    get new_user_session_path

    assert_response :success
    assert_no_match "Créer un compte", response.body
  end
end
