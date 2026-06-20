require "nokogiri"

class BrevoNewsletterParser
  KNOWN_THEMES = [
    "Qui suis-je ?",
    "Le coin des mamans",
    "Du grain à moudre",
    "Une œuvre d'art à savourer"
  ].freeze

  SKIP_PHRASES = [
    "Vous aussi vous souhaitez partager"
  ].freeze

  ARCHIVED_THEMES = [
    "Du grain à moudre"
  ].freeze

  FRENCH_MONTHS = {
    "janvier" => 1, "février" => 2, "mars" => 3, "avril" => 4,
    "mai" => 5, "juin" => 6, "juillet" => 7, "août" => 8,
    "septembre" => 9, "octobre" => 10, "novembre" => 11, "décembre" => 12
  }.freeze

  attr_reader :number, :date, :liturgical_context, :sections, :cover_caption

  def initialize(html)
    @doc = Nokogiri::HTML(html)
    parse_header
    parse_cover_caption
    parse_sections
  end

  private

  def parse_header
    @doc.css("div").each do |div|
      text = div.text.strip
      @number = $1.to_i if text =~ /\ALettre\s+(\d+)\z/
    end

    @doc.css("span").each do |span|
      text = span.text.strip
      if text =~ /\d{4}/
        parsed = parse_french_date(text)
        @date = parsed if parsed
      end
      if span.parent&.name == "i" || span.ancestors("i").any?
        ctx = text.strip
        @liturgical_context = ctx unless ctx.empty? || ctx =~ /\d{4}/
      end
    end
  end

  def parse_cover_caption
    img = @doc.at_css("img[src*='mailinblue'], img[src*='brevo']")
    return unless img

    caption_tr = img.ancestors("td").first&.ancestors("tr")&.first&.next_element
    return unless caption_tr

    caption_tr.css("br").each { |br| br.replace(Nokogiri::XML::Text.new(" — ", caption_tr.document)) }
    parts = caption_tr.css("p").map { |p| p.text.gsub(/\s+/, " ").strip }.reject(&:empty?)
    text  = parts.any? ? parts.join(" — ") : caption_tr.text.gsub(/\s+/, " ").strip
    @cover_caption = text.presence
  end

  def parse_sections
    h1s = @doc.css("h1.default-heading1")
    @sections = []

    h1s.each_with_index do |h1, idx|
      theme_name    = h1.text.strip.gsub(/\s+/, " ")
      matched_theme = KNOWN_THEMES.find { |t| theme_name.start_with?(t) }
      next unless matched_theme

      nodes = collect_nodes_until(h1, h1s[idx + 1])
      html  = nodes_to_html(nodes)
      next if html.strip.empty?

      @sections << { theme_name: matched_theme, html: html, archived: ARCHIVED_THEMES.include?(matched_theme) }
    end
  end

  def collect_nodes_until(start_node, stop_node)
    nodes = []
    start_node.document.traverse do |node|
      next unless node.is_a?(Nokogiri::XML::Element)
      break if stop_node && node == stop_node
      next if node == start_node
      next unless started_after?(node, start_node)
      nodes << node if relevant_node?(node)
    end
    nodes
  end

  def started_after?(node, reference)
    (node <=> reference) == 1
  rescue
    false
  end

  def relevant_node?(node)
    return false if SKIP_PHRASES.any? { |phrase| node.text.include?(phrase) }

    case node.name
    when "h2", "h3" then node.text.strip.present?
    when "p"         then node.text.strip.present? && node.ancestors("h1, h2, h3").none?
    when "img"       then node["src"].to_s.match?(/mailinblue|brevo/)
    when "a"         then node["href"].to_s.match?(/youtube\.com|youtu\.be/)
    else false
    end
  end

  def nodes_to_html(nodes)
    parts         = []
    skip_next_img = false

    nodes.each do |node|
      case node.name
      when "h2", "h3"
        parts << "<h3>#{node.inner_html.strip}</h3>"

      when "p"
        html = node.inner_html.strip
        next if html.blank? || html == "&nbsp;"
        parts << "<p>#{sanitize_inline(html)}</p>"

      when "a"
        href = node["href"].to_s
        if href.match?(/youtube\.com|youtu\.be/)
          parts << %(<p><a href="#{href}">▶ Voir la vidéo</a></p>)
          skip_next_img = true
        end

      when "img"
        if skip_next_img
          skip_next_img = false
          next
        end
        src     = node["src"].to_s
        alt     = node["alt"].to_s
        caption = find_caption(node)
        parts << "<figure>"
        parts << %( <img src="#{src}" alt="#{alt}">)
        parts << %( <figcaption>#{sanitize_inline(caption)}</figcaption>) if caption.present?
        parts << "</figure>"
      end
    end

    parts.join("\n")
  end

  def find_caption(img_node)
    candidate = img_node.parent
    5.times { candidate = candidate&.next_element }
    return nil unless candidate
    text = candidate.text.strip
    text.length < 300 ? text : nil
  end

  def sanitize_inline(html)
    html
      .gsub(/<span[^>]*>/, "")
      .gsub("</span>", "")
      .gsub(/\s*style="[^"]*"/, "")
      .gsub(/\s*class="[^"]*"/, "")
      .gsub(/color:\s*#[0-9a-fA-F]{3,6};?/, "")
      .gsub("<a ", '<a target="_blank" ')
      .strip
  end

  def parse_french_date(text)
    text = text.gsub(/\A\w+\s+/, "")
    return unless text =~ /(\d+)\s+(\w+)\s+(\d{4})/
    day, month_str, year = $1.to_i, $2.downcase, $3.to_i
    month = FRENCH_MONTHS[month_str]
    Date.new(year, month, day) if month
  end
end
