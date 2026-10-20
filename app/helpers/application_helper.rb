module ApplicationHelper
  # Campaign amounts are in the collective's currency (USD), whatever the locale : "$20,000", "20 000 $"
  def money(amount)
    number_to_currency(amount, unit: "$", precision: 0)
  end

  # Text shown in uppercase (.display, .label, .btn) : "OpenCutList" keeps its camel case
  def brand(text)
    safe_join(text.to_s.split(/(OpenCutList)/).map { |part| part == "OpenCutList" ? tag.span(part, class: "normal-case") : part })
  end

  # Header link : the current page is a solid orange block, like the checked tool of the Smart toolbar.
  # highlight : always on a pink block (Support), outlined in white when current.
  def nav_link_to(path, highlight: false, &)
    active = current_page?(path)
    style = if highlight then [ "bg-lab text-white hover:bg-white hover:text-ink", "outline-2 outline-offset-2 outline-white" => active ]
    else active ? "bg-brand text-white" : "hover:bg-white/10"
    end
    link_to(path, class: class_names("px-2 sm:px-2.5 py-1 whitespace-nowrap transition-colors", style),
                  "aria-current": ("page" if active), &)
  end

  def page_title
    content_for?(:title) ? "#{content_for(:title)} · OpenCutList" : t("site.title")
  end

  # The same page in the other locales, for the switcher and hreflang
  def alternate_locales
    I18n.available_locales - [ I18n.locale ]
  end

  def locale_url(locale)
    url_for(locale:, only_path: false)
  end

  # link_to opening in a new tab : (name, url, options) or (url, options) { name }
  def external_link_to(*args, **options, &)
    link_to(*args, { target: "_blank", rel: "noopener" }.merge(options), &)
  end

  def smart_icons
    %w[draw build reshape handle axes paint export]
  end
end
