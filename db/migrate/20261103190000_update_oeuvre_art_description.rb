class UpdateOeuvreArtDescription < ActiveRecord::Migration[8.1]
  OLD_DESCRIPTION = "Pour le plaisir des yeux, du cœur, de l'esprit ou des oreilles – de la nourriture pour l'âme ✨ " \
                    "parce que si \"l'homme ne vit pas seulement de pain\" (Mt 4,4), la femme non plus, en fait."
  NEW_DESCRIPTION = "Pour le plaisir des yeux, des oreilles, et du cœur"

  def up
    update_description(NEW_DESCRIPTION)
  end

  def down
    update_description(OLD_DESCRIPTION)
  end

  private

  def update_description(description)
    execute "UPDATE themes SET description = #{connection.quote(description)} " \
            "WHERE name = 'Une œuvre d''art à savourer'"
  end
end
