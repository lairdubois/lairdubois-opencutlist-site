require "test_helper"

class OpenCollectiveTest < ActiveSupport::TestCase
  test "a failing API gives nil" do
    Net::HTTP.stub_start_with(-> { raise SocketError, "offline" }) do
      assert_nil OpenCollective.stats
    end
  end

  test "parses the stats" do
    body = { data: { collective: { stats: { balance: { valueInCents: 123_456, currency: "USD" }, contributorsCount: 42 } } } }.to_json
    response = Net::HTTPOK.new("1.1", "200", "OK")
    response.instance_variable_set(:@body, body)
    response.instance_variable_set(:@read, true)
    Net::HTTP.stub_start_with(-> { response }) do
      stats = OpenCollective.stats
      assert_equal 1234, stats.balance
      assert_equal 42, stats.contributors
      assert_equal "USD", stats.currency
    end
  end
end

# Net::HTTP.start answering with the lambda's result (no network)
class << Net::HTTP
  def stub_start_with(answer)
    original = method(:start)
    define_singleton_method(:start) { |*, **| answer.call }
    yield
  ensure
    define_singleton_method(:start, original)
  end
end
