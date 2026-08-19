class DashboardController < ApplicationController
  def index
    @p = portfolio
    @period = (params[:period].presence_in(%w[day week month year all]) || "month")

    @kpi = {
      nav: @p.nav,
      capital: @p.capital_in,
      cash: @p.cash,
      market_value: @p.market_value,
      realized: @p.realized_total,
      unrealized: @p.unrealized_total,
      net: @p.net_pnl,
      return_pct: @p.total_return_pct,
      period_pnl: @p.pnl_for(@period)
    }

    @stats = @p.stats
    @positions = @p.positions
    @t0_rows = @p.t0_rows
    @recent_trades = current_account.trades.includes(:stock).recent.limit(8)
    @equity_curve = @p.equity_curve
    @period_series = period_series(@p)
    @latest_insight = AiInsight.status_done.recent.first
  end

  private

  # Chuỗi P&L realized theo đơn vị hợp với khoảng đang xem.
  def period_series(p)
    granularity = case @period
    when "day", "week" then :day
    when "year", "all" then :month
    else :day
    end
    p.realized_series(granularity)
  end
end
