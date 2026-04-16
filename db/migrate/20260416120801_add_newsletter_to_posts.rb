class AddNewsletterToPosts < ActiveRecord::Migration[8.1]
  def change
    add_reference :posts, :newsletter, null: true, foreign_key: true
  end
end
