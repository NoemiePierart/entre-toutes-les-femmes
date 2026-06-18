require "nokogiri"
require "net/http"
require "uri"

namespace :posts do
  desc "Backfill thumbnails by downloading the first image found in each post's content"
  task backfill_thumbnails: :environment do
    posts = Post.includes(:rich_text_content)
                .where.not(action_text_rich_texts: { body: nil })

    puts "#{posts.count} posts à traiter..."
    attached = 0
    skipped = 0
    errors = 0

    posts.each do |post|
      if post.thumbnail.attached?
        skipped += 1
        next
      end

      html = post.content.body.to_html
      doc = Nokogiri::HTML.fragment(html)
      img = doc.at_css("img[src]")

      unless img
        skipped += 1
        next
      end

      src = img["src"]

      begin
        image_data = download_image(src)
        unless image_data
          puts "  [#{post.id}] Impossible de télécharger #{src}"
          errors += 1
          next
        end

        filename = File.basename(URI.parse(src).path).presence || "thumbnail.jpg"
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
    end

    puts "\nTerminé : #{attached} thumbnails attachés, #{skipped} ignorés, #{errors} erreurs."
  end

  def download_image(url, redirects_left = 5)
    return nil if redirects_left == 0

    uri = URI.parse(url)
    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https", open_timeout: 10, read_timeout: 15) do |http|
      http.get(uri.request_uri)
    end

    case res
    when Net::HTTPSuccess
      { body: res.body, content_type: res["content-type"]&.split(";")&.first }
    when Net::HTTPRedirection
      download_image(res["location"], redirects_left - 1)
    else
      nil
    end
  end
end
