require "json"
require "digest"
require "pathname"

namespace :brevo do
  BACKUP_DIR = Rails.root.join("backup/brevo")

  desc "Download all images from backup HTML files into each backup folder"
  task backup_images: :environment do
    folders = Dir.glob(BACKUP_DIR.join("*/")).sort
    puts "#{folders.count} dossiers à traiter...\n\n"
    total_images = 0
    total_covers = 0

    folders.each do |folder_path|
      folder    = Pathname.new(folder_path)
      html_file = folder.join("content.html")
      map_file  = folder.join("images_map.json")

      unless html_file.exist?
        puts "[#{folder.basename}] ⚠ content.html absent, ignoré"
        next
      end

      if map_file.exist? && (folder.join("cover.jpg").exist? || folder.join("cover.png").exist?)
        puts "[#{folder.basename}] déjà traité, ignoré"
        next
      end

      html       = File.read(html_file)
      doc        = Nokogiri::HTML(html)
      images_dir = folder.join("images")
      FileUtils.mkdir_p(images_dir)

      # Identify cover URL using the same selector as BrevoSyncJob
      cover_tag = doc.css("img[src*='mailinblue'], img[src*='brevo'], img[src*='sendinblue']").first
      cover_url = cover_tag&.[]("src").to_s

      images_map    = {}
      cover_saved   = false
      folder_images = 0

      doc.css("img[src]").each do |img_tag|
        url = img_tag["src"].to_s.strip
        next if url.empty? || url.start_with?("data:")
        next if images_map.key?(url)

        image_data = ImageDownloader.download(url)
        unless image_data
          puts "  ✗ #{url.truncate(80)}"
          images_map[url] = nil
          next
        end

        raw_ct = image_data[:content_type].to_s
        ext = case raw_ct
              when /png/  then "png"
              when /gif/  then "gif"
              when /webp/ then "webp"
              else "jpg"
              end

        filename = "#{Digest::SHA1.hexdigest(url)[0..11]}.#{ext}"
        File.binwrite(images_dir.join(filename), image_data[:body])
        images_map[url] = { "path" => "images/#{filename}", "content_type" => raw_ct.split(";").first }

        if !cover_saved && url == cover_url
          File.binwrite(folder.join("cover.#{ext}"), image_data[:body])
          File.write(folder.join("cover_content_type"), raw_ct.split(";").first)
          cover_saved = true
        end

        folder_images += 1
        sleep 0.1
      rescue => e
        puts "  ✗ #{url.truncate(60)}: #{e.message}"
        images_map[url] = nil
      end

      File.write(map_file, JSON.pretty_generate(images_map))
      total_images += folder_images
      total_covers += 1 if cover_saved

      status = cover_saved ? "cover ✓" : "cover ✗"
      puts "[#{folder.basename}] #{folder_images} images, #{status}"
    end

    puts "\nTerminé : #{total_images} images téléchargées, #{total_covers} covers sauvegardées."
  end
end
