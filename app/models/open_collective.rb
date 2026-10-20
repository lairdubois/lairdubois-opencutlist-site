require "net/http"

# Campaign figures from the Open Collective GraphQL API (public, no token), cached for a while.
# The amount is the collective's current balance : what it holds now, fees and expenses removed.
# Any failure gives nil : pages then show no gauge rather than an error.
module OpenCollective
  API_URL = URI("https://api.opencollective.com/graphql/v2")
  TTL = 15.minutes

  Stats = Data.define(:balance_cents, :currency, :contributors) do
    def balance = balance_cents / 100
  end

  QUERY = <<~GRAPHQL
    query($slug: String!) {
      collective(slug: $slug) {
        stats {
          balance { valueInCents currency }
          contributorsCount
        }
      }
    }
  GRAPHQL

  extend self

  def stats(slug: Site.collective)
    Rails.cache.fetch([ "open_collective/stats", slug ], expires_in: TTL, skip_nil: true, race_condition_ttl: 30.seconds) do
      fetch(slug)
    end
  end

  private

  def fetch(slug)
    response = Net::HTTP.start(API_URL.host, API_URL.port, use_ssl: true, open_timeout: 3, read_timeout: 5) do |http|
      body = { query: QUERY, variables: { slug: } }.to_json
      http.post(API_URL.path, body, "Content-Type" => "application/json", "Accept" => "application/json")
    end
    raise "HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    stats = JSON.parse(response.body).dig("data", "collective", "stats") or raise "no stats in #{response.body.first(200)}"
    Stats.new(balance_cents: stats.dig("balance", "valueInCents").to_i, currency: stats.dig("balance", "currency"),
              contributors: stats["contributorsCount"].to_i)
  rescue StandardError => e
    Rails.logger.warn("Open Collective stats unavailable : #{e.class} #{e.message}")
    nil
  end
end
