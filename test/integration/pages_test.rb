require "test_helper"

class PagesTest < ActionDispatch::IntegrationTest
  STATS = OpenCollective::Stats.new(balance_cents: 512_345, currency: "USD", contributors: 2487)

  test "every page renders in every locale" do
    with_campaign(STATS) do
      %w[en fr].each do |locale|
        %w[/ /lab /download /donate].each do |page|
          get "/#{locale}#{page}".chomp("/")
          assert_response :success, "#{locale}#{page}"
          assert_select "html[lang=#{locale}]"
          assert_select "link[rel=alternate][hreflang=#{(%w[en fr] - [ locale ]).first}]"
        end
      end
    end
  end

  test "OpenCutList keeps its camel case in uppercase text" do
    with_campaign(STATS) do
      %w[en fr].each do |locale|
        %w[/ /lab /download /donate].each do |page|
          get "/#{locale}#{page}".chomp("/")
          uppercased = Nokogiri::HTML(response.body).css(".display, .label, .btn").flat_map { |node| node.xpath(".//text()") }
          offending = uppercased.select { |text| text.content.include?("OpenCutList") && !text.parent.classes.include?("normal-case") }
          assert_empty offending.map(&:content), "#{locale}#{page}"
        end
      end
    end
  end

  test "download links" do
    get "/en/download"
    assert_select "a[href='#{Site.stable.url}']"
    assert_select "a.btn[href='/en/lab']"
  end

  test "the gauge shows the balance against the goal" do
    with_campaign(STATS) { get "/en/donate" }
    assert_select "[role=progressbar][aria-valuenow='25']"
    assert_select "p.display", text: "25%"
    assert_match "$5,123", response.body
    assert_match "2,487 contributors", response.body
  end

  test "no gauge without Open Collective" do
    with_campaign(nil) { get "/en" }
    assert_response :success
    assert_select "[role=progressbar]", count: 0
  end

  test "the LAB page lists the released episodes and the next one" do
    travel_to Date.new(2026, 11, 6) do
      get "/en/lab"
    end
    assert_match "Trailer", response.body
    assert_match "Smart Draw", response.body
    assert_match "Smart Build Divider", response.body
    assert_no_match "Smart Build Front Panel", response.body
  end
end
