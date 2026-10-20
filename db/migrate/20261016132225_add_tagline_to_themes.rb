class AddTaglineToThemes < ActiveRecord::Migration[8.1]
  TAGLINES = {
    "Qui suis-je ?" => "Le mystère de la vocation féminine, à la lumière de la foi",
    "Le coin des mamans" => "S'encourager à vivre une maternité exigeante",
    "Une œuvre d'art à savourer" => "Pour le plaisir des yeux, du cœur et des oreilles"
  }.freeze

  def up
    add_column :themes, :tagline, :string

    # Seeds don't run on deploy, so the existing themes get their tagline here.
    TAGLINES.each do |name, tagline|
      execute <<~SQL.squish
        UPDATE themes SET tagline = #{connection.quote(tagline)} WHERE name = #{connection.quote(name)}
      SQL
    end
  end

  def down
    remove_column :themes, :tagline
  end
end
