require "test_helper"

class ThemesControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    theme = Theme.create!(name: "Pensées diverses")
    get theme_url(theme)
    assert_response :success
  end

  test "locally stored theme image is served through Active Storage" do
    theme = Theme.create!(name: "Mystère féminin")
    theme.sync_image!

    get theme_url(theme)

    assert_match %r{background-image: url\('/rails/active_storage/}, response.body
    assert_select ".theme-show-credit", theme.image_credit
  end

  test "Cloudinary theme image is served from Cloudinary" do
    theme = Theme.create!(name: "Mystère féminin")
    blob = ActiveStorage::Blob.create!(
      key: "production-key", filename: "image.jpg", byte_size: 1, checksum: "x",
      content_type: "image/jpeg", service_name: "cloudinary"
    )
    ActiveStorage::Attachment.create!(record: theme, name: "image", blob: blob)

    get theme_url(theme)

    assert_match %r{background-image: url\('https://res\.cloudinary\.com/[^']*production-key}, response.body
  end
end
