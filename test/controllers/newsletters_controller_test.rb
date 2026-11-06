require "test_helper"

class NewslettersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @newsletter = Newsletter.create!(number: 12, published_on: Date.new(2024, 3, 3))
  end

  test "index is public and lists the letters" do
    get newsletters_url

    assert_response :success
    assert_select "a[href='#{newsletter_path(@newsletter)}']"
  end

  test "show is public and found by number" do
    get newsletter_url(@newsletter)

    assert_response :success
    assert_equal "/lettres/12", newsletter_path(@newsletter)
  end

  test "show returns 404 for an unknown number" do
    get newsletter_url(id: 999)

    assert_response :not_found
  end
end
