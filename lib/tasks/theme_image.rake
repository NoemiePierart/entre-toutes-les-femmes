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

# Separate block so each namespace block stays short
namespace :themes do
  desc "Replace theme images whose file in db/seeds/theme_images has changed"
  task sync_images: :environment do
    # Analyze the new images right away: production has no job worker
    ActiveJob::Base.queue_adapter = :inline

    Theme.order(:id).each do |theme|
      if theme.image_file.nil?
        puts "  – #{theme.name} : pas de fichier db/seeds/theme_images/#{theme.to_param}.(jpg|png|webp)"
      elsif theme.image_up_to_date?
        puts "  = #{theme.name} : inchangée"
      else
        theme.sync_image!
        puts "  ✓ #{theme.name} : image remplacée par #{File.basename(theme.image_file)}"
      end
    end
  end
end
