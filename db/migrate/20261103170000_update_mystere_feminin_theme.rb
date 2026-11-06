class UpdateMystereFemininTheme < ActiveRecord::Migration[8.1]
  OLD_DESCRIPTION = "Pour entrer dans le mystère de la vocation féminine avec les lunettes 😎 de la foi, " \
                    "à partir d'écrits philosophiques, théologiques, artistiques, de la Bible, des arts…"
  NEW_DESCRIPTION = "Pour penser la féminité à la lumière de la foi"

  def up
    execute <<~SQL
      UPDATE themes SET name = 'Mystère féminin', description = #{quote(NEW_DESCRIPTION)}
      WHERE name = 'Qui suis-je ?'
    SQL
  end

  def down
    execute <<~SQL
      UPDATE themes SET name = 'Qui suis-je ?', description = #{quote(OLD_DESCRIPTION)}
      WHERE name = 'Mystère féminin'
    SQL
  end

  private

  def quote(value)
    connection.quote(value)
  end
end
