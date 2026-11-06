class UpdateCoinDesMamansDescription < ActiveRecord::Migration[8.1]
  OLD_DESCRIPTION = "Des contenus sur-mesure pour s'encourager mutuellement à vivre une maternité exigeante ♥️"
  NEW_DESCRIPTION = "Pour s’encourager à vivre une maternité exigeante"

  def up
    execute "UPDATE themes SET description = #{connection.quote(NEW_DESCRIPTION)} WHERE name = 'Le coin des mamans'"
  end

  def down
    execute "UPDATE themes SET description = #{connection.quote(OLD_DESCRIPTION)} WHERE name = 'Le coin des mamans'"
  end
end
