# Idempotent seeds — safe to run multiple times.

# Admin user
admin = User.find_or_create_by!(email: "admin@entretouteslesfemmes.fr") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
  u.admin = true
end

# Themes
qui_suis_je = Theme.find_or_create_by!(name: "Qui suis-je ?").tap do |t|
  t.update!(description: "Pour entrer dans le mystère de la vocation féminine avec les lunettes de la foi, à partir d'écrits philosophiques, théologiques, artistiques, de la Bible, des arts…")
end

coin_des_mamans = Theme.find_or_create_by!(name: "Le coin des mamans").tap do |t|
  t.update!(description: "Des contenus sur-mesure pour s'encourager mutuellement à vivre une maternité exigeante")
end

grain_a_moudre = Theme.find_or_create_by!(name: "Du grain à moudre").tap do |t|
  t.update!(archived: true)
end

oeuvre_art = Theme.find_or_create_by!(name: "Une œuvre d'art à savourer").tap do |t|
  t.update!(description: "Pour le plaisir des yeux, du cœur, de l'esprit ou des oreilles – de la nourriture pour l'âme parce que si \"l'homme ne vit pas seulement de pain\" (Mt 4,4), la femme non plus, en fait.")
end

# Theme images
{
  qui_suis_je     => "db/seeds/theme_images/qui_suis_je.jpg",
  coin_des_mamans => "db/seeds/theme_images/coin_des_mamans.png",
  oeuvre_art      => "db/seeds/theme_images/oeuvre_art.jpg"
}.each do |theme, path|
  unless theme.image.attached?
    theme.image.attach(
      io:           File.open(Rails.root.join(path)),
      filename:     File.basename(path),
      content_type: path.end_with?(".png") ? "image/png" : "image/jpeg"
    )
  end
end

puts "Seed terminé : #{Newsletter.count} lettres, #{Theme.count} thèmes, #{Post.count} articles, #{User.count} utilisateurs."
