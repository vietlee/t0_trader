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
    @equity_curve = @p.equity_curve

    # Dữ liệu biểu đồ tổng quan
    @allocation = @positions.select { |p| p.market_value.to_i.positive? }
                            .map { |p| [p.stock.symbol, p.market_value.to_i] }
    @asset_mix = [["Tiền mặt", @p.cash.to_i], ["Cổ phiếu", @p.market_value.to_i]]
                 .select { |_, v| v.positive? }
    @unrealized_by_stock = @positions.select { |p| p.market_price }
                                     .map { |p| [p.stock.symbol, p.unrealized.to_i] }
                                     .sort_by { |_, v| -v }
    @realized_by_stock = @p.realized_events.group_by { |e| e.stock&.symbol }
                           .transform_values { |evs| evs.sum(&:pnl).to_i }
                           .reject { |k, _| k.nil? }
                           .sort_by { |_, v| -v }.to_h
  end
end
