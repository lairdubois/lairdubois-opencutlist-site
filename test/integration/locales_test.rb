require "test_helper"

class LocalesTest < ActionDispatch::IntegrationTest
  test "root redirects to the browser's first available language" do
    get "/", headers: { "Accept-Language" => "de-DE,fr;q=0.8,en;q=0.5" }
    assert_redirected_to "/fr"
    assert_equal "Accept-Language", response.headers["Vary"]
  end

  test "qualities win over order" do
    get "/", headers: { "Accept-Language" => "en;q=0.3,fr-CA" }
    assert_redirected_to "/fr"
  end

  test "english without a known language" do
    get "/", headers: { "Accept-Language" => "de,it;q=0.5" }
    assert_redirected_to "/en"
    get "/"
    assert_redirected_to "/en"
  end

  test "a refused language is skipped" do
    get "/", headers: { "Accept-Language" => "fr;q=0,en" }
    assert_redirected_to "/en"
  end

  test "short campaign links keep their page" do
    get "/lab", headers: { "Accept-Language" => "fr" }
    assert_redirected_to "/fr/lab"
  end

  test "unknown locales are not found" do
    get "/de"
    assert_response :not_found
  end
end
