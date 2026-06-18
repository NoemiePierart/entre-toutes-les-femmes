class AddDescriptionToThemes < ActiveRecord::Migration[8.1]
  def change
    add_column :themes, :description, :text
  end
end
