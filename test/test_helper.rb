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

  class MemoryInstrumenter
    def initialize
      @events = {}
    end

    def instrument(event, payload = {})
      @events[event] ||= []
      @events[event] <<  payload
      yield payload if block_given?
    end

    def events_for(event)
      @events[event]
    end

    def count(event)
      @events[event] ? @events[event].count : 0
    end
  end
end
