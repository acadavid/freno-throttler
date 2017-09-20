$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
# Elsewhere after Bundler has loaded gems e.g. after `require 'bundler/setup'`
require "freno/throttler"
require "mocha/mini_test"
require "minitest/autorun"

class Freno::Throttler::Test < Minitest::Test

  def client(faraday: nil)
    Freno::Client.new(faraday) do |freno|
      freno.default_store_type = :mysql
    end
  end
end
