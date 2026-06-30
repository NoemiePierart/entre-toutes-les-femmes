module ApplicationHelper
  include Pagy::Frontend

  def absolute_asset_url(attachment)
    url = url_for(attachment)
    url.start_with?("http") ? url : request.base_url + url
  end

  def variant_url(attachment, **transforms)
    blob = attachment.blob
    crop_type = transforms[:resize_to_fill] ? :fill : :limit
    dims = transforms[:resize_to_limit] || transforms[:resize_to_fill]
    cl_options = { quality: :auto }
    cl_options.merge!(width: dims[0], height: dims[1], crop: crop_type) if dims
    cl_options[:format] = transforms[:format] if transforms[:format]
    Cloudinary::Utils.cloudinary_url("entre-toutes-les-femmes/#{blob.key}", cl_options)
  rescue StandardError
    url_for(attachment.variant(**transforms))
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

  def post_display_content(post)
    return with_image_sources(post.content) unless post.theme.name == "Qui suis-je ?"

    doc = Nokogiri::HTML.fragment(post.content.to_s)
    doc.at_css("h3")&.remove
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
