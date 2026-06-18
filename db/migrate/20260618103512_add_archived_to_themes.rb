class AddArchivedToThemes < ActiveRecord::Migration[8.1]
  def change
    add_column :themes, :archived, :boolean, default: false, null: false
  end
end
