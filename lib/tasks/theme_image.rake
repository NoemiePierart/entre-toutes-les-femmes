namespace :themes do
  desc "Assign a post's thumbnail as a theme image. Usage: bin/rails themes:set_image[theme_id,post_id]"
  task :set_image, [ :theme_id, :post_id ] => :environment do |_, args|
    theme = Theme.find(args[:theme_id])
    post  = Post.unscoped.find(args[:post_id])

    abort "Ce post n'a pas de thumbnail." unless post.thumbnail.attached?

    blob = post.thumbnail.blob
    theme.image.attach(blob)
    puts "✓ Image de \"#{theme.name}\" définie depuis le post #{post.id} (#{post.title.truncate(50)})"
  end

  desc "List all themes with their current image status"
  task list: :environment do
    Theme.order(:id).each do |t|
      status = t.image.attached? ? "✓ image" : "✗ pas d'image"
      puts "  [#{t.id}] #{t.name.ljust(30)} #{status}"
    end
  end
end
