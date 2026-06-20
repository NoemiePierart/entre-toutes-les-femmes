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
