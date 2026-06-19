require "net/http"
require "json"

class BrevoClient
  API_BASE = "https://api.brevo.com/v3"

  def initialize(api_key: ENV.fetch("BREVO_API_KEY"))
    @api_key = api_key
  end

  def all_campaigns(status: "sent")
    campaigns = []
    offset    = 0
    loop do
      data  = get("/emailCampaigns?type=classic&status=#{status}&limit=50&offset=#{offset}&sort=desc")
      batch = data["campaigns"] || []
      campaigns.concat(batch)
      break if campaigns.size >= data["count"].to_i || batch.empty?
      offset += 50
    end
    campaigns
  end

  def campaign(id)
    get("/emailCampaigns/#{id}")
  end

  private

  def get(path, retries: 4)
    uri = URI("#{API_BASE}#{path}")
    req = Net::HTTP::Get.new(uri)
    req["api-key"] = @api_key
    req["accept"]  = "application/json"
    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }

    if res.code == "429" && retries > 0
      wait = 2 ** (4 - retries) * 10
      Rails.logger.warn "Brevo rate limit (429) — attente #{wait}s"
      sleep wait
      return get(path, retries: retries - 1)
    end

    raise "Brevo API error #{res.code}: #{res.body}" unless res.is_a?(Net::HTTPSuccess)
    JSON.parse(res.body)
  end
end
