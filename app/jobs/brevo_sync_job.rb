require "net/http"
require "json"

class BrevoSyncJob < ApplicationJob
  queue_as :default

  SKIP_LETTERS = [ 60 ].freeze

  def perform(campaign_id)
    client   = BrevoClient.new
    campaign = client.campaign(campaign_id)

    letter_number = campaign["name"].scan(/\d+/).first.to_i
    return if SKIP_LETTERS.include?(letter_number)
    return if campaign["name"] !~ /Lettre\s+\d+/i
    return if Newsletter.exists?(number: letter_number)

    parser = BrevoNewsletterParser.new(campaign["htmlContent"])
    number = parser.number || letter_number
    date   = parser.date || Date.parse(campaign["sentDate"])
    admin  = User.find_by!(admin: true)

    newsletter = Newsletter.create!(
      number:             number,
      published_on:       date,
      liturgical_context: parser.liturgical_context,
      cover_caption:      parser.cover_caption
    )

    parser.sections.each do |section|
      post = Post.new(
        title:      "#{section[:theme_name]} — Lettre #{number}",
        theme:      Theme.find_by!(name: section[:theme_name]),
        newsletter: newsletter,
        user:       admin,
        archived:   section[:archived]
      )
      post.content = section[:html]
      post.save!
    end

    attach_cover_image(newsletter, campaign["htmlContent"])
    generate_thumbnails(newsletter)
    generate_titles(newsletter)

    Rails.logger.info "BrevoSyncJob: Lettre #{number} importée avec succès."
  end

  private

  def attach_cover_image(newsletter, html_content)
    return if newsletter.cover_image.attached?

    doc = Nokogiri::HTML(html_content.to_s)
    img = doc.css("img[src*='mailinblue'], img[src*='brevo']").first
    return unless img

    image_data = ImageDownloader.download(img["src"])
    return unless image_data

    filename = File.basename(URI.parse(img["src"]).path).presence || "cover.jpg"
    newsletter.cover_image.attach(
      io:           StringIO.new(image_data[:body]),
      filename:     filename,
      content_type: image_data[:content_type] || "image/jpeg"
    )
  end

  def generate_thumbnails(newsletter)
    newsletter.posts.includes(:rich_text_content).each do |post|
      next if post.thumbnail.attached?

      doc = Nokogiri::HTML.fragment(post.content.body.to_html)
      img = doc.at_css("img[src]")
      next unless img

      image_data = ImageDownloader.download(img["src"])
      next unless image_data

      filename = File.basename(URI.parse(img["src"]).path).presence || "thumbnail.jpg"
      post.thumbnail.attach(
        io:           StringIO.new(image_data[:body]),
        filename:     filename,
        content_type: image_data[:content_type] || "image/jpeg"
      )
    rescue => e
      Rails.logger.warn "BrevoSyncJob thumbnail [post #{post.id}]: #{e.message}"
    end
  end

  def generate_titles(newsletter)
    api_key = ENV["ANTHROPIC_API_KEY"]
    return unless api_key

    newsletter.posts.each do |post|
      next unless post.title.match?(/^.+ — Lettre \d+/)

      content = post.content.to_plain_text.strip
      next if content.blank?

      title = fetch_title(post, api_key)
      post.update_columns(title: title) if title.present?
      sleep 0.3
    end
  end

  def fetch_title(post, api_key)
    prompt = <<~PROMPT
      Tu es éditrice d'un blog catholique francophone pour femmes. Voici un article de la rubrique "#{post.theme.name}".

      Génère un titre court et percutant (5 à 8 mots maximum) pour cet article. Le titre peut être :
      - une citation courte extraite du texte
      - un titre nominal frappant
      - une question centrale

      Réponds UNIQUEMENT avec le titre, sans guillemets, sans ponctuation finale, sans explication.

      Contenu de l'article :
      #{post.content.to_plain_text.first(2000)}
    PROMPT

    uri = URI("https://api.anthropic.com/v1/messages")
    req = Net::HTTP::Post.new(uri)
    req["x-api-key"]         = api_key
    req["anthropic-version"] = "2023-06-01"
    req["content-type"]      = "application/json"
    req.body = JSON.generate({
      model:     "claude-haiku-4-5-20251001",
      max_tokens: 60,
      messages:  [ { role: "user", content: prompt } ]
    })

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
    return nil unless res.is_a?(Net::HTTPSuccess)

    JSON.parse(res.body).dig("content", 0, "text")&.strip
  rescue => e
    Rails.logger.warn "BrevoSyncJob title [post #{post.id}]: #{e.message}"
    nil
  end
end
