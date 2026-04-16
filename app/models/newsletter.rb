class Newsletter < ApplicationRecord
  has_many :posts, dependent: :destroy

  validates :number, presence: true, uniqueness: true
  validates :published_on, presence: true

  def to_param
    number.to_s
  end
end
