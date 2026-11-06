# Idempotent seeds — safe to run multiple times.

# Admin user
admin = User.find_or_create_by!(email: "admin@entretouteslesfemmes.fr") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
  u.admin = true
end

# Themes
# Renamed from "Qui suis-je ?": rename an existing record rather than creating a second theme
Theme.find_by(name: "Qui suis-je ?")&.update!(name: "Mystère féminin")
Theme.find_or_create_by!(name: "Mystère féminin").tap do |t|
  t.update!(description: "Pour penser la féminité à la lumière de la foi")
end

Theme.find_or_create_by!(name: "Le coin des mamans").tap do |t|
  t.update!(description: "Pour s’encourager à vivre une maternité exigeante")
end

grain_a_moudre = Theme.find_or_create_by!(name: "Du grain à moudre").tap do |t|
  t.update!(archived: true)
end

Theme.find_or_create_by!(name: "Une œuvre d'art à savourer").tap do |t|
  t.update!(description: "Pour le plaisir des yeux, des oreilles, et du cœur")
end

Theme.find_or_create_by!(name: "Pensées diverses").tap do |t|
  t.update!(description: "Pour… tout le reste")
end

# Theme images
# Attached only when missing; use bin/rails themes:sync_images to replace them
Theme.find_each do |theme|
  theme.sync_image! if theme.image_file && !theme.image.attached?
end

puts "Seed terminé : #{Newsletter.count} lettres, #{Theme.count} thèmes, #{Post.count} articles, #{User.count} utilisateurs."
