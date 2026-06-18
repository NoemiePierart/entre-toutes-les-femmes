class AddArchivedToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :archived, :boolean, default: false, null: false
  end
end
