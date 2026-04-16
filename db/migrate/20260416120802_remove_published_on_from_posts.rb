class RemovePublishedOnFromPosts < ActiveRecord::Migration[8.1]
  def change
    remove_column :posts, :published_on, :date
  end
end
