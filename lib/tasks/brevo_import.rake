require "net/http"
require "json"
require "nokogiri"
require "open-uri"

namespace :brevo do
  BREVO_API_BASE = "https://api.brevo.com/v3"
  SKIP_LETTERS   = [ 60 ].freeze

  # Theme names exactly as they appear in the newsletter h1 headings
  KNOWN_THEMES = [
    "Qui suis-je ?",
    "Le coin des mamans",
    "Du grain à moudre",
    "Une œuvre d'art à savourer"
  ].freeze

  # h1 headings that are NOT posts — skip them
  SKIP_SECTIONS = [
    "Cette semaine",
    "Entre toutes les femmes"
  ].freeze

  def brevo_get(path, retries: 4)
    uri = URI("#{BREVO_API_BASE}#{path}")
    req = Net::HTTP::Get.new(uri)
    req["api-key"] = ENV.fetch("BREVO_API_KEY")
    req["accept"]  = "application/json"
    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }

    if res.code == "429" && retries > 0
      wait = 2 ** (4 - retries) * 10  # 10s, 20s, 40s, 80s
      puts "  Rate limit (429) — attente de #{wait}s avant de réessayer…"
      sleep wait
      return brevo_get(path, retries: retries - 1)
    end

    raise "Brevo API error #{res.code}: #{res.body}" unless res.is_a?(Net::HTTPSuccess)
    JSON.parse(res.body)
  end

  def brevo_all_campaigns
    campaigns = []
    offset    = 0
    limit     = 50
    loop do
      data  = brevo_get("/emailCampaigns?type=classic&status=sent&limit=#{limit}&offset=#{offset}&sort=desc")
      batch = data["campaigns"] || []
      campaigns.concat(batch)
      break if campaigns.size >= data["count"].to_i || batch.empty?
      offset += limit
    end
    campaigns
  end

  # ─── Parsing helpers ────────────────────────────────────────────────────────

  # Extract newsletter number and date from parsed HTML.
  def parse_header(doc)
    number = nil
    date   = nil
    liturgical_context = nil

    doc.css("div").each do |div|
      text = div.text.strip
      if text =~ /\ALettre\s+(\d+)\z/
        number = $1.to_i
      end
    end

    # Date cell contains e.g. "dimanche 19 janvier 2024"
    doc.css("span").each do |span|
      text = span.text.strip
      if text =~ /\d{4}/
        parsed = parse_french_date(text)
        date = parsed if parsed
      end
      # Liturgical context: italicised text like "2e dimanche du Temps Ordinaire"
      if span.parent&.name == "i" || span.ancestors("i").any?
        ctx = text.strip
        liturgical_context = ctx unless ctx.empty? || ctx =~ /\d{4}/
      end
    end

    [ number, date, liturgical_context ]
  end

  FRENCH_MONTHS = {
    "janvier" => 1, "février" => 2, "mars" => 3, "avril" => 4,
    "mai" => 5, "juin" => 6, "juillet" => 7, "août" => 8,
    "septembre" => 9, "octobre" => 10, "novembre" => 11, "décembre" => 12
  }.freeze

  def parse_french_date(text)
    text = text.gsub(/\A\w+\s+/, "") # strip day name
    if text =~ /(\d+)\s+(\w+)\s+(\d{4})/
      day, month_str, year = $1.to_i, $2.downcase, $3.to_i
      month = FRENCH_MONTHS[month_str]
      return Date.new(year, month, day) if month
    end
    nil
  end

  # Walk the h1 elements and collect sections between them.
  # Returns [{theme_name:, nodes:[]}, ...]
  def extract_sections(doc)
    h1s = doc.css("h1.default-heading1")
    sections = []

    h1s.each_with_index do |h1, idx|
      theme_name = h1.text.strip.gsub(/\s+/, " ")
      next unless KNOWN_THEMES.any? { |t| theme_name.start_with?(t) }

      # Collect all sibling/cousin nodes until the next h1
      next_h1 = h1s[idx + 1]
      content_nodes = collect_nodes_until(h1, next_h1)

      sections << { theme_name: KNOWN_THEMES.find { |t| theme_name.start_with?(t) }, nodes: content_nodes }
    end

    sections
  end

  # Walk forward in the DOM from `start_node`, collecting nodes that appear
  # before `stop_node`. Works across table cell boundaries.
  def collect_nodes_until(start_node, stop_node)
    nodes = []
    stop_reached = false

    start_node.document.traverse do |node|
      next unless node.is_a?(Nokogiri::XML::Element)

      if stop_node && node == stop_node
        stop_reached = true
        break
      end

      # Only keep meaningful leaf-ish elements: p, div with text, h2, h3, img, a[href*=youtube]
      next if node == start_node
      next unless started_after?(node, start_node)

      nodes << node if relevant_node?(node)
    end

    nodes
  end

  def started_after?(node, reference)
    # Compare document position: node comes after reference
    (node <=> reference) == 1
  rescue
    false
  end

  def relevant_node?(node)
    case node.name
    when "h2", "h3"
      node.text.strip.present?
    when "p"
      node.text.strip.present? && node.ancestors("h1, h2, h3").none?
    when "img"
      src = node["src"].to_s
      src.include?("mailinblue") || src.include?("brevo")
    when "a"
      node["href"].to_s.include?("youtube.com") || node["href"].to_s.include?("youtu.be")
    else
      false
    end
  end

  # Convert collected nodes to clean ActionText-friendly HTML.
  def nodes_to_html(nodes)
    parts = []
    skip_next_img = false # used to skip YouTube thumbnails (the <a> handles them)

    nodes.each do |node|
      case node.name
      when "h2", "h3"
        parts << "<h3>#{node.inner_html.strip}</h3>"

      when "p"
        html = node.inner_html.strip
        next if html.blank? || html == "&nbsp;"
        # Strip Brevo tracking attributes but keep inline formatting
        html = sanitize_inline(html)
        parts << "<p>#{html}</p>"

      when "a"
        href = node["href"].to_s
        if href.include?("youtube.com") || href.include?("youtu.be")
          # Embed as a plain link with a label
          parts << "<p><a href=\"#{href}\">▶ Voir la vidéo</a></p>"
          skip_next_img = true
        end

      when "img"
        next if skip_next_img
        src = node["src"].to_s
        alt = node["alt"].to_s
        # Look for caption sibling
        caption = find_caption(node)
        parts << "<figure>"
        parts << "  <img src=\"#{src}\" alt=\"#{alt}\">"
        parts << "  <figcaption>#{sanitize_inline(caption)}</figcaption>" if caption.present?
        parts << "</figure>"
        skip_next_img = false
      end
    end

    parts.join("\n")
  end

  def find_caption(img_node)
    # Caption is typically in a small-font span right after the image's table cell
    candidate = img_node.parent
    5.times { candidate = candidate&.next_element }
    return nil unless candidate
    text = candidate.text.strip
    text.length < 300 ? text : nil
  end

  def sanitize_inline(html)
    # Remove colour spans that reference Brevo's palette colours; keep bold/italic/links
    html
      .gsub(/<span[^>]*>/, "")
      .gsub("</span>", "")
      .gsub(/\s*style="[^"]*"/, "")
      .gsub(/\s*class="[^"]*"/, "")
      .gsub(/color:\s*#[0-9a-fA-F]{3,6};?/, "")
      .gsub("<a ", '<a target="_blank" ')
      .strip
  end

  # ─── Tasks ──────────────────────────────────────────────────────────────────

  desc "List all Brevo campaigns"
  task list: :environment do
    brevo_all_campaigns.each do |c|
      puts "Brevo ##{c['id'].to_s.ljust(6)} #{c['name'].ljust(25)} #{c['sentDate']}"
    end
  end

  desc "Fetch one newsletter HTML to tmp/brevo_sample.html for inspection"
  task fetch_sample: :environment do
    campaigns = brevo_all_campaigns
    sample = campaigns.find { |c| SKIP_LETTERS.exclude?(c["name"].scan(/\d+/).first.to_i) }
    abort "Aucune campagne." unless sample

    puts "Récupération : #{sample['name']} (Brevo ID #{sample['id']})"
    detail = brevo_get("/emailCampaigns/#{sample['id']}")

    FileUtils.mkdir_p(Rails.root.join("tmp"))
    File.write(Rails.root.join("tmp/brevo_sample.html"), detail["htmlContent"] || "")
    File.write(Rails.root.join("tmp/brevo_sample.json"), JSON.pretty_generate(detail.except("htmlContent")))
    puts "Sauvegardé dans tmp/brevo_sample.{html,json}"
  end

  desc "Dry-run: show what would be imported without touching the database"
  task dry_run: :environment do
    admin      = User.find_by!(admin: true)
    campaigns  = brevo_all_campaigns

    campaigns.each do |campaign|
      letter_number = campaign["name"].scan(/\d+/).first.to_i
      next if SKIP_LETTERS.include?(letter_number)
      next unless campaign["name"] =~ /Lettre\s+\d+/i

      detail = brevo_get("/emailCampaigns/#{campaign['id']}")
      doc    = Nokogiri::HTML(detail["htmlContent"])

      number, date, liturgical_context = parse_header(doc)
      number ||= letter_number

      puts "\n── Lettre #{number} (#{date}) — #{liturgical_context}"

      extract_sections(doc).each do |section|
        html = nodes_to_html(section[:nodes])
        puts "   [#{section[:theme_name]}] #{html.length} caractères de contenu"
      end
    end

    puts "\nDry-run terminé."
  end

  desc "Import all newsletters from Brevo into the database"
  task import: :environment do
    admin     = User.find_by!(admin: true)
    campaigns = brevo_all_campaigns
    imported  = 0
    skipped   = 0

    campaigns.each do |campaign|
      letter_number = campaign["name"].scan(/\d+/).first.to_i
      if SKIP_LETTERS.include?(letter_number) || campaign["name"] !~ /Lettre\s+\d+/i
        puts "Ignoré : #{campaign['name']}"
        skipped += 1
        next
      end

      if Newsletter.exists?(number: letter_number)
        puts "Déjà importée : Lettre #{letter_number}"
        skipped += 1
        next
      end

      puts "Importation : #{campaign['name']} (Brevo ID #{campaign['id']})…"
      detail = brevo_get("/emailCampaigns/#{campaign['id']}")
      doc    = Nokogiri::HTML(detail["htmlContent"])

      number, date, liturgical_context = parse_header(doc)
      number ||= letter_number
      date   ||= Date.parse(campaign["sentDate"]) rescue nil

      unless date
        puts "  ⚠ Date introuvable pour Lettre #{number}, ignorée."
        skipped += 1
        next
      end

      newsletter = Newsletter.create!(
        number:            number,
        published_on:      date,
        liturgical_context: liturgical_context
      )

      extract_sections(doc).each do |section|
        theme = Theme.find_by!(name: section[:theme_name])
        html  = nodes_to_html(section[:nodes])
        next if html.strip.empty?

        post = Post.new(
          title:      "#{section[:theme_name]} — Lettre #{number}",
          theme:      theme,
          newsletter: newsletter,
          user:       admin
        )
        post.content = html
        post.save!
        print "  ✓ #{section[:theme_name]}\n"
      end

      imported += 1
      sleep 2  # stay within Brevo campaigns API rate limit
    end

    puts "\nTerminé : #{imported} lettres importées, #{skipped} ignorées."
  end
end
