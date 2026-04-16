class Post < ApplicationRecord
  belongs_to :theme
  belongs_to :user
  belongs_to :newsletter

  has_rich_text :content

  validates :title, presence: true
end
