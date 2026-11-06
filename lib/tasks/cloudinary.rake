require "net/http"

namespace :cloudinary do
  desc "Copy the original images from another Cloudinary cloud into the configured one. Usage: bin/rails cloudinary:copy_from[ds1dbi6qk]"
  task :copy_from, [ :cloud_name ] => :environment do |_, args|
    source = args[:cloud_name].presence
    abort "Indiquez le cloud d'origine : bin/rails cloudinary:copy_from[ds1dbi6qk]" unless source
    abort "Le cloud configuré est déjà #{source}, rien à copier." if Cloudinary.config.cloud_name == source

    # Only the originals: resized variants are rebuilt by Cloudinary on demand
    blobs = ActiveStorage::Blob.where(service_name: "cloudinary")
      .where(id: ActiveStorage::Attachment.where(record_type: %w[Post Newsletter Theme]).select(:blob_id))
      .order(:id).to_a
    puts "#{blobs.size} images à copier de #{source} vers #{Cloudinary.config.cloud_name}"

    copied = skipped = 0
    failed = []
    blobs.each do |blob|
      if blob.service.exist?(blob.key)
        skipped += 1
        next
      end

      response = Net::HTTP.get_response(URI("https://res.cloudinary.com/#{source}/image/upload/v1/entre-toutes-les-femmes/#{blob.key}"))
      if !response.is_a?(Net::HTTPSuccess)
        failed << "blob #{blob.id} : HTTP #{response.code}"
      elsif Digest::MD5.base64digest(response.body) != blob.checksum
        failed << "blob #{blob.id} : fichier téléchargé différent de l'original"
      else
        blob.service.upload(blob.key, StringIO.new(response.body), checksum: blob.checksum)
        copied += 1
        print "."
      end
    rescue StandardError => e
      failed << "blob #{blob.id} : #{e.class} #{e.message}"
    end

    puts "\n✓ #{copied} copiées, #{skipped} déjà présentes, #{failed.size} en échec"
    failed.each { |line| puts "  ✗ #{line}" }
    exit 1 if failed.any?
  end
end
