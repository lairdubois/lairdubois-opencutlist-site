class PagesController < ApplicationController
  before_action :load_campaign, only: %i[home lab support]

  def home
  end

  def lab
    @episodes = Site.visible_episodes
  end

  def download
  end

  def support
  end

  private

  def load_campaign
    @campaign = OpenCollective.stats
  end
end
