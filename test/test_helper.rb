ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)

    # Replaces OpenCollective.stats (no network in tests) for the block
    def with_campaign(stats)
      original = OpenCollective.method(:stats)
      OpenCollective.define_singleton_method(:stats) { |**| stats }
      yield
    ensure
      OpenCollective.define_singleton_method(:stats, original)
    end
  end
end
