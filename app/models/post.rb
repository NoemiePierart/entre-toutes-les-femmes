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
      .order(Arel.sql(sanitize_sql_array([ "md5(posts.id::text || ?)", date.iso8601 ])))
  }

  def to_param
    "#{id}-#{title.parameterize}"
  end

  def cover_image
    thumbnail.attached? ? thumbnail : theme.image
  end

  # Mystère féminin shows the letter's own heading. A heading that is all one
  # quotation loses its quotes; quotes inside it become French « ».
  def display_title
    return title unless theme.name == "Mystère féminin"

    text = source_title
    text = text[1..-2].strip if text.match?(/\A"[^"]*"\z/)
    text.gsub(/"([^"]*)"/) { "«\u00A0#{$1.strip}\u00A0»" }.sub(/[[:alpha:]]/, &:upcase)
  end

  def cover_image?
    thumbnail.attached? || theme.image.attached?
  end

  # Opening lines of the content, without the title it starts with, the
  # "[Lettre 21 : …]" reminder or the "Chères mamans," greeting.
  def excerpt(length = 170)
    text = content.to_plain_text.squish
    # The heading's case can differ from the title's ("bienheureuse" / "Bienheureuse")
    text = text[source_title.length..].strip if text.downcase.start_with?(source_title.downcase)
    text = text.sub(/\A\[[^\]]*\]\s*/, "").sub(/\AChères mamans,?\s*/i, "")
    # Paragraphs can end up glued together ("(1897)A savourer"): restore the space.
    text = text.gsub(/([)\]])(\p{L})/, '\1 \2').gsub(/([.!?»]|\p{Ll})(\p{Lu})(?=[\p{Ll}\s'’])/, '\1 \2')
    text.sub(/[[:alpha:]]/, &:upcase).truncate(length, separator: " ", omission: "…")
  end

  private

  # The title as written: the letter's heading for Mystère féminin, read as text
  # so entities like &nbsp; come out as characters
  def source_title
    return title unless theme.name == "Mystère féminin"

    heading = Nokogiri::HTML.fragment(rich_text_content.body.to_html).at_css("h3")&.text&.squish
    heading.presence || title
  end
end
