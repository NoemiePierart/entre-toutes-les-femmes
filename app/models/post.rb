class Post < ApplicationRecord
  default_scope { where(archived: false) }

  belongs_to :theme
  belongs_to :user
  belongs_to :newsletter

  has_rich_text :content
  has_one_attached :thumbnail

  validates :title, presence: true

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
end
