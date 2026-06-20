class AddCoverCaptionToNewsletters < ActiveRecord::Migration[8.1]
  def change
    add_column :newsletters, :cover_caption, :string
  end
end
