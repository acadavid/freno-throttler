require "test_helper"

class Freno::ThrottlerTest < Freno::Throttler::Test

  def test_that_it_has_a_version_number
    refute_nil Freno::Throttler::VERSION
  end

  def test_throttle_runs_the_block_when_all_stores_have_caught_up
    block_called = false
    throttler = Freno::Throttler.new(client, :github, ->(context) {[]})
    throttler.throttle do
      block_called = true
    end
    assert block_called, "block should have been called"
  end

  def test_sleeps_when_a_check_fails_and_then_calls_the_block
    block_called = false

    stub = client
    stub.expects(:check?).times(2).with(app: :github, store_name: :mysqla).returns(false).then.returns(true)

    throttler = Freno::Throttler.new(stub, :github, ->(context) {[:mysqla]})
    throttler.expects(:wait).once.returns(0.1)

    throttler.throttle do
      block_called = true
    end

    assert block_called, "block should have been called"
  end

  def test_raises_waited_too_long_if_freno_checks_failed_consistenly
    block_called = false

    stub = client
    stub.expects(:check?).at_least(3).with(app: :github, store_name: :mysqla).returns(false)

    throttler = Freno::Throttler.new(stub, :github, ->(context) {[:mysqla]}, wait_seconds: 0.1, max_wait_seconds: 0.3)
    throttler.expects(:wait).times(3).returns(0.1)

    assert_raises(Freno::Throttler::WaitedTooLong) do
      throttler.throttle do
        block_called = true
      end
    end

    refute block_called, "block should not have been called"
  end

  def test_raises_a_specific_error_in_case_freno_itself_errored
    block_called = false

    stub = client
    stub.expects(:check?).raises(Freno::Error)

    throttler = Freno::Throttler.new(stub, :github, ->(context) {[:mysqla]}, wait_seconds: 0.1, max_wait_seconds: 0.3)
    throttler.expects(:wait).never

    assert_raises(Freno::Throttler::ClientError) do
      throttler.throttle do
        block_called = true
      end
    end

    refute block_called, "block should not have been called"
  end
end
