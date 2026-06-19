require "net/http"
require "uri"

class ImageDownloader
  def self.download(url, redirects_left: 5)
    return nil if redirects_left.zero?

    uri = URI.parse(url)
    res = Net::HTTP.start(uri.hostname, uri.port,
      use_ssl: uri.scheme == "https",
      open_timeout: 10,
      read_timeout: 15
    ) { |http| http.get(uri.request_uri) }

    case res
    when Net::HTTPSuccess
      { body: res.body, content_type: res["content-type"]&.split(";")&.first }
    when Net::HTTPRedirection
      download(res["location"], redirects_left: redirects_left - 1)
    end
  end
end
