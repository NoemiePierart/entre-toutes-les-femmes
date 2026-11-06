class CreatePenseesDiversesTheme < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      INSERT INTO themes (name, description, archived, created_at, updated_at)
      SELECT 'Pensées diverses', 'Pour… tout le reste', false, NOW(), NOW()
      WHERE NOT EXISTS (SELECT 1 FROM themes WHERE name = 'Pensées diverses')
    SQL
  end

  def down
    execute "DELETE FROM themes WHERE name = 'Pensées diverses'"
  end
end
