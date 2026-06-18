class Post < ApplicationRecord
  default_scope { where(archived: false) }

  belongs_to :theme
  belongs_to :user
  belongs_to :newsletter

  has_rich_text :content
  has_one_attached :thumbnail

  validates :title, presence: true
end
