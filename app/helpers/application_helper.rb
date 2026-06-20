module ApplicationHelper
  include Pagy::Frontend

  def absolute_asset_url(attachment)
    url = url_for(attachment)
    url.start_with?("http") ? url : request.base_url + url
  end

  def with_image_sources(content)
    return content if content.blank?

    doc = Nokogiri::HTML.fragment(content.to_s)
    doc.css("figure").each do |figure|
      node = figure.next_sibling
      node = node.next_sibling while node&.text? && node.text.strip.empty?
      while node&.element? && node.name == "p"
        classes = node["class"].to_s.split
        node["class"] = (classes | ["image-source"]).join(" ")
        node = node.next_sibling
        node = node.next_sibling while node&.text? && node.text.strip.empty?
      end
    end

    doc.to_html.html_safe
  end
end
