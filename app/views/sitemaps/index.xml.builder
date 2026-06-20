xml.instruct! :xml, version: "1.0", encoding: "UTF-8"
xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9" do
  xml.url do
    xml.loc root_url
    xml.changefreq "weekly"
    xml.priority "1.0"
  end

  xml.url do
    xml.loc newsletters_url
    xml.changefreq "weekly"
    xml.priority "0.8"
  end

  @themes.each do |theme|
    xml.url do
      xml.loc theme_url(theme)
      xml.changefreq "monthly"
      xml.priority "0.7"
    end
  end

  @newsletters.each do |newsletter|
    xml.url do
      xml.loc newsletter_url(newsletter)
      xml.lastmod newsletter.published_on.iso8601
      xml.changefreq "monthly"
      xml.priority "0.6"
    end
  end

  @posts.each do |post|
    xml.url do
      xml.loc post_url(post)
      xml.lastmod post.newsletter.published_on.iso8601
      xml.changefreq "monthly"
      xml.priority "0.5"
    end
  end
end
