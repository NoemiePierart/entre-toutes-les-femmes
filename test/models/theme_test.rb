require "test_helper"

class ThemeTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "image_file is found from the theme slug" do
    assert_equal "mystere-feminin.jpg", File.basename(Theme.new(name: "Mystère féminin").image_file)
    assert_nil Theme.new(name: "Rubrique sans image").image_file
  end

  test "sync_image! attaches the reference file and is then up to date" do
    theme = Theme.create!(name: "Mystère féminin")
    assert_not theme.image_up_to_date?

    theme.sync_image!

    assert theme.reload.image.attached?
    assert theme.image_up_to_date?
  end

  test "sync_image! never deletes a previous image stored on another service" do
    theme = Theme.create!(name: "Mystère féminin")
    production_blob = ActiveStorage::Blob.create!(
      key: "production-key", filename: "ancienne.jpg", byte_size: 1, checksum: "x",
      content_type: "image/jpeg", service_name: "cloudinary"
    )
    ActiveStorage::Attachment.create!(record: theme, name: "image", blob: production_blob)

    assert_no_enqueued_jobs(only: ActiveStorage::PurgeJob) { theme.sync_image! }

    assert ActiveStorage::Blob.exists?(production_blob.id)
    assert theme.reload.image_up_to_date?
  end
end
