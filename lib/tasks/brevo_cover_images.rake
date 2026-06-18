require "net/http"
require "json"
require "nokogiri"
require "uri"

namespace :newsletters do
  desc "Download cover images from Brevo HTML and attach them to each Newsletter"
  task backfill_cover_images: :environment do
    api_key = ENV.fetch("BREVO_API_KEY") { abort "BREVO_API_KEY manquant" }

    newsletters = Newsletter.all.order(:number)
    puts "#{newsletters.count} newsletters à traiter..."
    attached = 0
    skipped  = 0
    errors   = 0

    newsletters.each do |newsletter|
      if newsletter.cover_image.attached?
        skipped += 1
        next
      end

      campaign = brevo_find_campaign(newsletter.number, api_key)
      unless campaign
        puts "  [Lettre #{newsletter.number}] Campagne Brevo introuvable"
        errors += 1
        next
      end

      detail = brevo_fetch_campaign(campaign["id"], api_key)
      unless detail
        puts "  [Lettre #{newsletter.number}] Erreur API"
        errors += 1
        next
      end

      html = detail["htmlContent"].to_s
      doc  = Nokogiri::HTML(html)
      img  = doc.css("img[src*='mailinblue'], img[src*='brevo']").first

      unless img
        puts "  [Lettre #{newsletter.number}] Aucune image Brevo trouvée"
        skipped += 1
        next
      end

      src = img["src"]
      image_data = download_image(src)
      unless image_data
        puts "  [Lettre #{newsletter.number}] Impossible de télécharger #{src}"
        errors += 1
        next
      end

      filename    = File.basename(URI.parse(src).path).presence || "cover.jpg"
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

  private

  def brevo_find_campaign(number, api_key)
    offset = 0
    loop do
      uri = URI("https://api.brevo.com/v3/emailCampaigns?limit=50&offset=#{offset}&status=sent")
      req = Net::HTTP::Get.new(uri)
      req["api-key"] = api_key
      req["accept"]  = "application/json"
      res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
      return nil unless res.is_a?(Net::HTTPSuccess)

      data      = JSON.parse(res.body)
      campaigns = data["campaigns"] || []
      found     = campaigns.find { |c| c["name"].scan(/\d+/).first.to_i == number }
      return found if found
      break if campaigns.size < 50
      offset += 50
    end
    nil
  end

  def brevo_fetch_campaign(id, api_key)
    uri = URI("https://api.brevo.com/v3/emailCampaigns/#{id}")
    req = Net::HTTP::Get.new(uri)
    req["api-key"] = api_key
    req["accept"]  = "application/json"
    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
    return nil unless res.is_a?(Net::HTTPSuccess)
    JSON.parse(res.body)
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
    end
  end
end
