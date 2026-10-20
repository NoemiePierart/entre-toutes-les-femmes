class Theme < ApplicationRecord
  has_many :posts, dependent: :destroy
  has_one_attached :image

  validates :name, presence: true

  # Short subtitle shown on the homepage. Kept in code rather than in the
  # database: the production tables are owned by another PostgreSQL role,
  # so the app cannot add a column to them.
  TAGLINES = {
    "Qui suis-je ?" => "Le mystère de la vocation féminine, à la lumière de la foi",
    "Le coin des mamans" => "S'encourager à vivre une maternité exigeante",
    "Une œuvre d'art à savourer" => "Pour le plaisir des yeux, du cœur et des oreilles"
  }

  def tagline
    TAGLINES[name]
  end

  def to_param
    name.parameterize
  end
end
