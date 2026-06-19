require "nokogiri"

namespace :posts do
  desc "Backfill thumbnails by downloading the first image found in each post's content"
  task backfill_thumbnails: :environment do
    posts = Post.includes(:rich_text_content)
                .where.not(action_text_rich_texts: { body: nil })

    puts "#{posts.count} posts à traiter..."
    attached = 0
    skipped  = 0
    errors   = 0

    posts.each do |post|
      if post.thumbnail.attached?
        skipped += 1
        next
      end

      doc = Nokogiri::HTML.fragment(post.content.body.to_html)
      img = doc.at_css("img[src]")

      unless img
        skipped += 1
        next
      end

      image_data = ImageDownloader.download(img["src"])
      unless image_data
        puts "  [#{post.id}] Impossible de télécharger #{img['src']}"
        errors += 1
        next
      end

      filename     = File.basename(URI.parse(img["src"]).path).presence || "thumbnail.jpg"
      content_type = image_data[:content_type] || "image/jpeg"

      post.thumbnail.attach(
        io: StringIO.new(image_data[:body]),
        filename: filename,
        content_type: content_type
      )

      puts "  [#{post.id}] #{post.title.truncate(50)} → #{filename}"
      attached += 1
    rescue => e
      puts "  [#{post.id}] Erreur : #{e.message}"
      errors += 1
    end

    puts "\nTerminé : #{attached} thumbnails attachés, #{skipped} ignorés, #{errors} erreurs."
  end
end
