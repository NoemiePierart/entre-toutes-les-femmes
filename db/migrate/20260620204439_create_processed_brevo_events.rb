class CreateProcessedBrevoEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :processed_brevo_events do |t|
      t.integer :campaign_id, null: false
      t.timestamps
    end
    add_index :processed_brevo_events, :campaign_id, unique: true
  end
end
