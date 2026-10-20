class ApplicationController < ActionController::Base
  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  around_action :switch_locale

  private

  def switch_locale(&)
    I18n.with_locale(params[:locale].presence || I18n.default_locale, &)
  end

  def default_url_options
    { locale: I18n.locale }
  end
end
