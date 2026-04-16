class CreateNewsletters < ActiveRecord::Migration[8.1]
  def change
    create_table :newsletters do |t|
      t.integer :number
      t.date :published_on
      t.string :liturgical_context

      t.timestamps
    end
  end
end
