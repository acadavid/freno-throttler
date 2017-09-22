require "test_helper"

class Freno::ThrottlerTest < Freno::Throttler::Test

  def test_that_it_has_a_version_number
    refute_nil Freno::Throttler::VERSION
  end

  def test_validations
    ex = assert_raises(ArgumentError) do
      Freno::Throttler.new(wait_seconds: 1, max_wait_seconds: 0.5)
    end
    assert_match(/app must be provided/, ex.message)
    assert_match(/client must be provided/, ex.message)
    assert_match(/max_wait_seconds \(0.5\) has to be greather than wait_seconds \(1\)/, ex.message)
  end

  def test_using_the_default_identiy_mapper
    block_called = false

    stub = client
    stub.expects(:check?).once.with(app: :github, store_name: :mysqla)
      .returns(true)

    throttler = Freno::Throttler.new(client: stub, app: :github)

    throttler.throttle(:mysqla) do
      block_called = true
    end

    assert block_called, "block should have been called"
  end

  def test_throttle_runs_the_block_when_all_stores_have_caught_up
    block_called = false

    throttler = Freno::Throttler.new do |t|
      t.client = client
      t.app = :github
      t.mapper = ->(context) {[]}
      t.instrumenter = MemoryInstrumenter.new
    end

    throttler.throttle do
      block_called = true
    end
    assert block_called, "block should have been called"

    assert_equal 1, throttler.instrumenter.count("throttler.called")
    assert_equal 1, throttler.instrumenter.count("throttler.succeeded")
    assert_equal 0, throttler.instrumenter.count("throttler.waited")
    assert_equal 0, throttler.instrumenter.count("throttler.waited_too_long")
    assert_equal 0, throttler.instrumenter.count("throttler.freno_errored")
  end

  def test_sleeps_when_a_check_fails_and_then_calls_the_block
    block_called = false

    stub = client
    stub.expects(:check?).times(2).with(app: :github, store_name: :mysqla)
      .returns(false).then.returns(true)

    throttler = Freno::Throttler.new do |t|
      t.client = stub
      t.app = :github
      t.mapper = ->(context) {[:mysqla]}
      t.instrumenter = MemoryInstrumenter.new
    end
    throttler.expects(:wait).once.returns(0.1)

    throttler.throttle do
      block_called = true
    end

    assert block_called, "block should have been called"

    assert_equal 1, throttler.instrumenter.count("throttler.called")
    assert_equal 1, throttler.instrumenter.count("throttler.succeeded")
    assert_equal 1, throttler.instrumenter.count("throttler.waited")
    assert_equal 0, throttler.instrumenter.count("throttler.waited_too_long")
    assert_equal 0, throttler.instrumenter.count("throttler.freno_errored")
  end

  def test_raises_waited_too_long_if_freno_checks_failed_consistenly
    block_called = false

    stub = client
    stub.expects(:check?).at_least(3).with(app: :github, store_name: :mysqla)
      .returns(false)

    throttler = Freno::Throttler.new do |t|
      t.client = stub
      t.app = :github
      t.mapper = ->(context) {[:mysqla]}
      t.instrumenter = MemoryInstrumenter.new
      t.wait_seconds = 0.1
      t.max_wait_seconds = 0.3
    end

    throttler.expects(:wait).times(3).returns(0.1)

    assert_raises(Freno::Throttler::WaitedTooLong) do
      throttler.throttle do
        block_called = true
      end
    end

    refute block_called, "block should not have been called"

    assert_equal 1, throttler.instrumenter.count("throttler.called")
    assert_equal 0, throttler.instrumenter.count("throttler.succeeded")
    assert_equal 3, throttler.instrumenter.count("throttler.waited")
    assert_equal 1, throttler.instrumenter.count("throttler.waited_too_long")
    assert_equal 0, throttler.instrumenter.count("throttler.freno_errored")
  end

  def test_raises_a_specific_error_in_case_freno_itself_errored
    block_called = false

    stub = client
    stub.expects(:check?).raises(Freno::Error)

    throttler = Freno::Throttler.new do |t|
      t.client = stub
      t.app = :github
      t.mapper = ->(context) {[:mysqla]}
      t.instrumenter = MemoryInstrumenter.new
      t.wait_seconds = 0.1
      t.max_wait_seconds = 0.3
    end

    throttler.expects(:wait).never

    assert_raises(Freno::Throttler::ClientError) do
      throttler.throttle do
        block_called = true
      end
    end

    refute block_called, "block should not have been called"

    assert_equal 1, throttler.instrumenter.count("throttler.called")
    assert_equal 0, throttler.instrumenter.count("throttler.succeeded")
    assert_equal 0, throttler.instrumenter.count("throttler.waited")
    assert_equal 0, throttler.instrumenter.count("throttler.waited_too_long")
    assert_equal 1, throttler.instrumenter.count("throttler.freno_errored")
  end
end
