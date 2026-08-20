class ToolsController < ApplicationController
  def position_size
    @p = portfolio
    @cash = @p.cash.to_i
    @nav = @p.nav.to_i
    @risk_pct = current_user.risk_per_trade_pct
  end
end
