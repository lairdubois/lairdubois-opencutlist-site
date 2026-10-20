# "/" and "/lab" (the short links of the campaign) : redirects to the page in the browser's language.
class LocalesController < ApplicationController
  def redirect
    response.headers["Vary"] = "Accept-Language"
    path = params[:page] ? "/#{params[:page]}" : ""
    redirect_to "/#{preferred_locale}#{path}", status: :found
  end

  private

  # First available language of Accept-Language, by quality ("fr-CA,fr;q=0.9,en;q=0.8" → fr)
  def preferred_locale
    available = I18n.available_locales.map(&:to_s)
    ranges = request.headers["Accept-Language"].to_s.split(",").filter_map do |range|
      tag, *options = range.strip.split(";")
      quality = options.find { |option| option.strip.start_with?("q=") }&.strip&.delete_prefix("q=")&.to_f || 1.0
      [ tag.strip.downcase.split("-").first, quality ] if tag.present? && quality.positive?
    end
    ranges.sort_by.with_index { |(_, quality), index| [ -quality, index ] }
          .map(&:first).find { |language| available.include?(language) } || I18n.default_locale.to_s
  end
end
