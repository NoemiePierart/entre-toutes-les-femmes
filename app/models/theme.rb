class Theme < ApplicationRecord
  has_many :posts, dependent: :destroy
  has_one_attached :image

  validates :name, presence: true

  # Short subtitle shown on the homepage. Kept in code rather than in the
  # database: the production tables are owned by another PostgreSQL role,
  # so the app cannot add a column to them.
  TAGLINES = {
    "Mystère féminin" => "Pour penser la féminité à la lumière de la foi",
    "Le coin des mamans" => "Pour s’encourager à vivre une maternité exigeante",
    "Une œuvre d'art à savourer" => "Pour le plaisir des yeux, des oreilles, et du cœur",
    "Pensées diverses" => "Pour… tout le reste"
  }

  # Credit of the painting in db/seeds/theme_images, shown under the arch on
  # the homepage. Update it together with the image file.
  IMAGE_CREDITS = {
    "Mystère féminin" => "Jeune femme nue au miroir (1515) — Giovanni Bellini",
    "Le coin des mamans" => "Le Petit Déjeuner au lit (1897) — Mary Cassatt",
    "Une œuvre d'art à savourer" => "Nature morte au rideau (vers 1895) — Paul Cézanne",
    "Pensées diverses" => "Impression, soleil levant (1872) — Claude Monet"
  }

  def tagline
    TAGLINES[name]
  end

  def image_credit
    IMAGE_CREDITS[name]
  end

  def to_param
    name.parameterize
  end

  # The reference image lives in the repository, named after the theme's slug
  # (db/seeds/theme_images/mystere-feminin.jpg), so local and production
  # can be synced from the same file.
  IMAGES_DIR = Rails.root.join("db/seeds/theme_images")

  def image_file
    Dir.glob(IMAGES_DIR.join("#{to_param}.{jpg,jpeg,png,webp}")).first
  end

  def image_up_to_date?
    image.attached? && image.blob.checksum == Digest::MD5.file(image_file).base64digest
  end

  # Replaces the image with image_file. The previous file is only deleted when
  # it lives on this environment's own storage: locally, the database holds
  # production blobs, and .env holds the production Cloudinary credentials.
  def sync_image!
    previous = image.attachment
    blob = ActiveStorage::Blob.create_and_upload!(io: File.open(image_file), filename: File.basename(image_file))

    transaction do
      previous&.delete
      ActiveStorage::Attachment.create!(record: self, name: "image", blob: blob)
    end

    previous_blob = previous&.blob
    own_storage = previous_blob&.service_name == ActiveStorage::Blob.service.name.to_s
    previous_blob.purge_later if own_storage && previous_blob.attachments.none?
  end
end
