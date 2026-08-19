class PositionsController < ApplicationController
  def index
    @p = portfolio
    @positions = @p.positions
    @t0_rows = @p.t0_rows
    @total_available = @p.total_available_qty
    @total_pending = @p.total_pending_qty
    @market_value = @p.market_value
    @unrealized = @p.unrealized_total
  end
end
