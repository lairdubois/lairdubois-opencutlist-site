# Settings read from config/site.yml : releases, campaign, links, episodes.
module Site
  Release = Data.define(:version, :build, :url, :changelog_url)
  Episode = Data.define(:number, :date, :title, :url) do
    def released?(today = Date.current) = date <= today
  end

  extend self

  def config = Rails.configuration.x.site

  def stable = release(:stable)
  def lab = release(:lab)

  def link(name) = config.dig(:links, name).presence

  def campaign_goal = config.dig(:campaign, :goal)
  def campaign_currency = config.dig(:campaign, :currency)
  def collective = config.dig(:campaign, :collective)

  def episodes
    config[:episodes].each_with_index.map do |episode, number|
      Episode.new(number:, date: Date.parse(episode[:date].to_s), title: episode[:title], url: episode[:url].presence)
    end
  end

  # What the LAB page lists : the released episodes, then the next one
  def visible_episodes(today = Date.current)
    released, coming = episodes.partition { |episode| episode.released?(today) }
    released + coming.first(1)
  end

  private

  def release(name)
    settings = config.fetch(name)
    Release.new(version: settings[:version].to_s, build: settings[:build].presence,
                url: settings[:url], changelog_url: settings[:changelog_url].presence)
  end
end
