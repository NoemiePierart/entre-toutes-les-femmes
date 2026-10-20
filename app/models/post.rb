class Post < ApplicationRecord
  default_scope { where(archived: false) }

  belongs_to :theme
  belongs_to :user
  belongs_to :newsletter

  has_rich_text :content
  has_one_attached :thumbnail

  validates :title, presence: true

  # Posts with their own image, in an order that changes every day but stays
  # stable during the day, so the homepage feels fresh without new content.
  scope :daily_selection, lambda { |date = Date.current|
    joins(:thumbnail_attachment)
      .order(Arel.sql(sanitize_sql_array(["md5(posts.id::text || ?)", date.iso8601])))
  }

  def to_param
    "#{id}-#{title.parameterize}"
  end

  def cover_image
    thumbnail.attached? ? thumbnail : theme.image
  end

  def display_title
    return title unless theme.name == "Qui suis-je ?"
    (rich_text_content.body.to_html.match(/<h3[^>]*>(.*?)<\/h3>/i)&.captures&.first&.gsub(/<[^>]+>/, "") || title).sub(/[[:alpha:]]/) { |c| c.upcase }
  end

  def cover_image?
    thumbnail.attached? || theme.image.attached?
  end

  # Opening lines of the content, without the title it starts with, the
  # "[Lettre 21 : …]" reminder or the "Chères mamans," greeting.
  def excerpt(length = 170)
    text = content.to_plain_text.squish
    text = text.delete_prefix(display_title).strip if text.downcase.start_with?(display_title.downcase)
    text = text.sub(/\A\[[^\]]*\]\s*/, "").sub(/\AChères mamans,?\s*/i, "")
    # Paragraphs can end up glued together ("(1897)A savourer"): restore the space.
    text = text.gsub(/([)\]])(\p{L})/, '\1 \2').gsub(/([.!?»]|\p{Ll})(\p{Lu})(?=[\p{Ll}\s'’])/, '\1 \2')
    text.sub(/[[:alpha:]]/, &:upcase).truncate(length, separator: " ", omission: "…")
  end
end
