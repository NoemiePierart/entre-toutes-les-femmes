require "nokogiri"

namespace :newsletters do
  desc "Download cover images from Brevo HTML and attach them to each Newsletter"
  task backfill_cover_images: :environment do
    client    = BrevoClient.new
    campaigns = client.all_campaigns
    attached  = 0
    skipped   = 0
    errors    = 0

    newsletters = Newsletter.all.order(:number)
    puts "#{newsletters.count} newsletters à traiter..."

    newsletters.each do |newsletter|
      if newsletter.cover_image.attached?
        skipped += 1
        next
      end

      campaign = campaigns.find { |c| c["name"].scan(/\d+/).first.to_i == newsletter.number }
      unless campaign
        puts "  [Lettre #{newsletter.number}] Campagne Brevo introuvable"
        errors += 1
        next
      end

      detail = client.campaign(campaign["id"])
      doc    = Nokogiri::HTML(detail["htmlContent"].to_s)
      img    = doc.css("img[src*='mailinblue'], img[src*='brevo']").first

      unless img
        puts "  [Lettre #{newsletter.number}] Aucune image Brevo trouvée"
        skipped += 1
        next
      end

      image_data = ImageDownloader.download(img["src"])
      unless image_data
        puts "  [Lettre #{newsletter.number}] Impossible de télécharger #{img['src']}"
        errors += 1
        next
      end

      filename     = File.basename(URI.parse(img["src"]).path).presence || "cover.jpg"
      content_type = image_data[:content_type] || "image/jpeg"

      newsletter.cover_image.attach(
        io: StringIO.new(image_data[:body]),
        filename: filename,
        content_type: content_type
      )

      puts "  [Lettre #{newsletter.number}] #{filename}"
      attached += 1
      sleep 0.5
    end

    puts "\nTerminé : #{attached} images attachées, #{skipped} ignorées, #{errors} erreurs."
  end
end
