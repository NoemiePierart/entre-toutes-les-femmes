require "json"

namespace :brevo do
  SKIP_LETTERS = [ 60 ].freeze

  desc "List all Brevo campaigns"
  task list: :environment do
    BrevoClient.new.all_campaigns.each do |c|
      puts "Brevo ##{c['id'].to_s.ljust(6)} #{c['name'].ljust(25)} #{c['sentDate']}"
    end
  end

  desc "List Brevo contact lists (to find BREVO_LIST_ID)"
  task lists: :environment do
    BrevoClient.new.lists.each { |l| puts "#{l['id'].to_s.ljust(6)} #{l['name']}" }
  end

  desc "Register Brevo webhook for 'delivered' events (requires APP_URL and BREVO_WEBHOOK_SECRET)"
  task register_webhook: :environment do
    app_url = ENV.fetch("APP_URL")
    secret  = ENV.fetch("BREVO_WEBHOOK_SECRET")
    url     = "#{app_url}/webhooks/brevo?token=#{secret}"
    result  = BrevoClient.new.register_webhook(url)
    puts "Webhook enregistré (ID #{result['id']}) : #{url}"
  end

  desc "List registered Brevo webhooks"
  task list_webhooks: :environment do
    BrevoClient.new.webhooks.each do |w|
      puts "##{w['id']} [#{w['events'].join(', ')}] #{w['url']}"
    end
  end

  desc "Fetch one newsletter HTML to tmp/brevo_sample.html for inspection"
  task fetch_sample: :environment do
    client   = BrevoClient.new
    sample   = client.all_campaigns.find { |c| SKIP_LETTERS.exclude?(c["name"].scan(/\d+/).first.to_i) }
    abort "Aucune campagne." unless sample

    puts "Récupération : #{sample['name']} (Brevo ID #{sample['id']})"
    detail = client.campaign(sample["id"])

    FileUtils.mkdir_p(Rails.root.join("tmp"))
    File.write(Rails.root.join("tmp/brevo_sample.html"), detail["htmlContent"] || "")
    File.write(Rails.root.join("tmp/brevo_sample.json"), JSON.pretty_generate(detail.except("htmlContent")))
    puts "Sauvegardé dans tmp/brevo_sample.{html,json}"
  end

  desc "Dry-run: show what would be imported without touching the database"
  task dry_run: :environment do
    client = BrevoClient.new

    client.all_campaigns.each do |campaign|
      letter_number = campaign["name"].scan(/\d+/).first.to_i
      next if SKIP_LETTERS.include?(letter_number)
      next unless campaign["name"] =~ /Lettre\s+\d+/i

      detail = client.campaign(campaign["id"])
      parser = BrevoNewsletterParser.new(detail["htmlContent"])
      number = parser.number || letter_number

      puts "\n── Lettre #{number} (#{parser.date}) — #{parser.liturgical_context}"
      parser.sections.each { |s| puts "   [#{s[:theme_name]}] #{s[:html].length} caractères" }
    end

    puts "\nDry-run terminé."
  end

  desc "Full import pipeline: import + titles + thumbnails + cover images"
  task full_import: :environment do
    Rake::Task["brevo:import"].invoke
    Rake::Task["posts:generate_titles"].invoke
    Rake::Task["posts:backfill_thumbnails"].invoke
    Rake::Task["newsletters:backfill_cover_images"].invoke
  end

  desc "Full offline import from local backup: import + titles + thumbnails + cover images"
  task full_import_from_backup: :environment do
    Rake::Task["brevo:import_from_backup"].invoke
    Rake::Task["posts:generate_titles"].invoke
  end

  desc "Import all newsletters from local backup (no Brevo API calls)"
  task import_from_backup: :environment do
    require "pathname"

    backup_dir = Rails.root.join("backup/brevo")
    admin      = User.find_by!(admin: true)
    imported   = 0
    skipped    = 0

    folders = Dir.glob(backup_dir.join("*/")).sort_by do |f|
      basename = Pathname.new(f).basename.to_s
      [ basename.scan(/Lettre[_ ](\d+)/i).flatten.first.to_i, basename ]
    end

    puts "#{folders.count} dossiers dans le backup...\n\n"

    folders.each do |folder_path|
      folder        = Pathname.new(folder_path)
      metadata_file = folder.join("metadata.json")
      html_file     = folder.join("content.html")

      unless metadata_file.exist? && html_file.exist?
        puts "[#{folder.basename}] ⚠ fichiers manquants, ignoré"
        skipped += 1
        next
      end

      metadata      = JSON.parse(File.read(metadata_file))
      folder_name   = folder.basename.to_s
      letter_number = folder_name.scan(/Lettre[_ ](\d+)/i).flatten.first.to_i
      letter_number = metadata["name"].scan(/\d+/).first.to_i if letter_number.zero?

      if SKIP_LETTERS.include?(letter_number) || metadata["name"] !~ /Lettre\s+\d+/i
        puts "Ignoré : #{metadata['name']}"
        skipped += 1
        next
      end

      if Newsletter.exists?(number: letter_number)
        puts "Déjà importée : Lettre #{letter_number}"
        skipped += 1
        next
      end

      puts "Importation : #{metadata['name']}…"
      html   = File.read(html_file)
      parser = BrevoNewsletterParser.new(html)

      number     = parser.number || letter_number
      date_str   = metadata["sentDate"] || metadata["scheduledAt"]
      meta_date  = (Date.parse(date_str) rescue nil)
      parsed     = parser.date
      parsed     = nil if parsed && parsed.year < 2020
      date       = meta_date || parsed

      unless date
        puts "  ⚠ Date introuvable pour Lettre #{number}, ignorée."
        skipped += 1
        next
      end

      newsletter = Newsletter.create!(
        number:             number,
        published_on:       date,
        liturgical_context: parser.liturgical_context,
        cover_caption:      parser.cover_caption
      )

      images_map = load_backup_images_map(folder)

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
        attach_backup_thumbnail(post, section[:html], folder, images_map)
        puts "  ✓ #{section[:theme_name]}"
      end

      attach_backup_cover(newsletter, folder, images_map, html)
      imported += 1
    end

    puts "\nTerminé : #{imported} lettres importées, #{skipped} ignorées."
  end

  desc "Import all newsletters from Brevo into the database"
  task import: :environment do
    admin    = User.find_by!(admin: true)
    client   = BrevoClient.new
    imported = 0
    skipped  = 0

    client.all_campaigns.each do |campaign|
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
      detail = client.campaign(campaign["id"])
      parser = BrevoNewsletterParser.new(detail["htmlContent"])

      number = parser.number || letter_number
      date   = parser.date || (Date.parse(campaign["sentDate"]) rescue nil)

      unless date
        puts "  ⚠ Date introuvable pour Lettre #{number}, ignorée."
        skipped += 1
        next
      end

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
        puts "  ✓ #{section[:theme_name]}"
      end

      imported += 1
      sleep 2
    end

    puts "\nTerminé : #{imported} lettres importées, #{skipped} ignorées."
  end
end

def load_backup_images_map(folder)
  map_file = folder.join("images_map.json")
  return {} unless map_file.exist?
  JSON.parse(File.read(map_file))
rescue JSON::ParserError
  {}
end

def attach_backup_cover(newsletter, folder, images_map, html)
  return if newsletter.cover_image.attached?

  # Try local cover file first
  %w[jpg png gif webp].each do |ext|
    cover_file = folder.join("cover.#{ext}")
    next unless cover_file.exist?

    content_type_file = folder.join("cover_content_type")
    content_type = content_type_file.exist? ? File.read(content_type_file).strip : "image/jpeg"
    newsletter.cover_image.attach(
      io:           File.open(cover_file),
      filename:     "cover.#{ext}",
      content_type: content_type
    )
    return
  end

  # Fallback: find first Brevo-hosted image in HTML and download
  doc = Nokogiri::HTML(html)
  img = doc.css("img[src*='mailinblue'], img[src*='brevo'], img[src*='sendinblue']").first
  img ||= doc.at_css("img[src]")
  return unless img

  src = img["src"].to_s

  # Check images_map first
  if (entry = images_map[src])
    local_path = folder.join(entry["path"] || entry)
    if local_path.exist?
      newsletter.cover_image.attach(
        io:           File.open(local_path),
        filename:     File.basename(local_path.to_s),
        content_type: entry.is_a?(Hash) ? entry["content_type"] : "image/jpeg"
      )
      return
    end
  end

  # Last resort: download from URL
  image_data = ImageDownloader.download(src)
  return unless image_data

  filename = File.basename(URI.parse(src).path).presence || "cover.jpg"
  newsletter.cover_image.attach(
    io:           StringIO.new(image_data[:body]),
    filename:     filename,
    content_type: image_data[:content_type] || "image/jpeg"
  )
rescue => e
  Rails.logger.warn "import_from_backup cover [newsletter #{newsletter.id}]: #{e.message}"
end

def attach_backup_thumbnail(post, section_html, folder, images_map)
  return if post.thumbnail.attached?

  doc = Nokogiri::HTML.fragment(section_html.to_s)
  img = doc.at_css("img[src]")
  return unless img

  src = img["src"].to_s

  if (entry = images_map[src])
    local_path = folder.join(entry.is_a?(Hash) ? entry["path"] : entry)
    if local_path.exist?
      content_type = entry.is_a?(Hash) ? entry["content_type"] : "image/jpeg"
      post.thumbnail.attach(
        io:           File.open(local_path),
        filename:     File.basename(local_path.to_s),
        content_type: content_type || "image/jpeg"
      )
      return
    end
  end

  # Fallback: download from URL
  image_data = ImageDownloader.download(src)
  return unless image_data

  filename = File.basename(URI.parse(src).path).presence || "thumbnail.jpg"
  post.thumbnail.attach(
    io:           StringIO.new(image_data[:body]),
    filename:     filename,
    content_type: image_data[:content_type] || "image/jpeg"
  )
rescue => e
  Rails.logger.warn "import_from_backup thumbnail [post #{post.id}]: #{e.message}"
end
