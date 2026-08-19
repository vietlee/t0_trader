require "test_helper"

class FeeCalculatorTest < ActiveSupport::TestCase
  test "phí mua theo mặc định 0.15%" do
    r = FeeCalculator.for(side: "buy", quantity: 1000, price: 100_000)
    assert_equal 100_000_000, r[:gross]
    assert_equal 150_000, r[:fee]
    assert_equal 0, r[:tax]
  end

  test "bán có thêm thuế 0.1%" do
    r = FeeCalculator.for(side: "sell", quantity: 1000, price: 100_000)
    assert_equal 150_000, r[:fee]
    assert_equal 100_000, r[:tax]
  end
end
