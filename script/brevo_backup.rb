#!/usr/bin/env ruby
# Usage: BREVO_API_KEY=your_key ruby script/brevo_backup.rb
# Output: tmp/brevo_backup/

require "net/http"
require "json"
require "fileutils"

API_KEY = ENV["BREVO_API_KEY"] or abort("Missing BREVO_API_KEY environment variable")
BASE_URL = "https://api.brevo.com/v3"
OUTPUT_DIR = File.expand_path("../../backup/brevo", __FILE__)

def get(path)
  uri = URI("#{BASE_URL}#{path}")
  req = Net::HTTP::Get.new(uri)
  req["api-key"] = API_KEY
  req["Accept"] = "application/json"
  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
  abort("API error #{res.code}: #{res.body}") unless res.is_a?(Net::HTTPSuccess)
  JSON.parse(res.body)
end

def safe_filename(str)
  str.gsub(/[^\w\-]/, "_").squeeze("_").slice(0, 60)
end

FileUtils.mkdir_p(OUTPUT_DIR)

# Fetch all sent campaigns (Brevo max 50 per page)
all_campaigns = []
offset = 0

loop do
  data = get("/emailCampaigns?status=sent&limit=50&offset=#{offset}")
  page = data["campaigns"] || []
  all_campaigns.concat(page)
  print "."
  break if page.length < 50
  offset += 50
end

puts "\nFound #{all_campaigns.length} campaigns"

# Save a quick index for reference
index = all_campaigns.map { |c| c.slice("id", "name", "subject", "sentDate") }
File.write("#{OUTPUT_DIR}/index.json", JSON.pretty_generate(index))

# Fetch and save each campaign
all_campaigns.each_with_index do |campaign, i|
  id   = campaign["id"]
  name = safe_filename(campaign["name"].to_s)
  date = campaign["sentDate"]&.slice(0, 10) || "unknown"

  print "[#{i + 1}/#{all_campaigns.length}] #{campaign["name"]} ... "

  detail = get("/emailCampaigns/#{id}")

  dir = File.join(OUTPUT_DIR, "#{date}_#{id}_#{name}")
  FileUtils.mkdir_p(dir)

  # Save metadata without the bulky HTML
  metadata = detail.reject { |k, _| k == "htmlContent" }
  File.write("#{dir}/metadata.json", JSON.pretty_generate(metadata))

  # Save the full HTML email
  File.write("#{dir}/content.html", detail["htmlContent"] || "")

  puts "saved"
  sleep 0.3 # stay well within Brevo rate limits
end

puts "\nDone! Backup saved to: #{OUTPUT_DIR}"
puts "#{all_campaigns.length} newsletters, #{all_campaigns.length * 2} files"
