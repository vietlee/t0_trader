class ReportsController < ApplicationController
  def index
    @p = portfolio
    events = @p.realized_events

    @monthly = @p.realized_series(:month)
    @stats = @p.stats
    @fees_total = @p.fees_total

    # Lời/lỗ theo mã
    @by_stock = events.group_by { |e| e.stock }.map do |stock, evs|
      { stock: stock, pnl: evs.sum(&:pnl), trades: evs.map(&:sell_trade_id).uniq.size }
    end.sort_by { |r| -r[:pnl] }

    # Lời/lỗ theo chiến lược (nhãn trên lệnh bán)
    tag_by_sell = current_account.trades.side_sell.where(id: events.map(&:sell_trade_id))
                                 .pluck(:id, :strategy_tag).to_h
    @by_tag = events.group_by { |e| tag_by_sell[e.sell_trade_id].presence || "(không nhãn)" }
                    .map { |tag, evs| { tag: tag, pnl: evs.sum(&:pnl), trades: evs.map(&:sell_trade_id).uniq.size } }
                    .sort_by { |r| -r[:pnl] }

    # Phí theo tháng
    @fees_by_month = current_account.trades.executed
                                    .group_by { |t| t.traded_at.strftime("%Y-%m") }
                                    .transform_values { |ts| ts.sum { |t| t.fee.to_d + t.tax.to_d } }
                                    .sort.to_h

    @realized_total = @p.realized_total
    @unrealized_total = @p.unrealized_total
    @expectancy = @p.expectancy
    @max_drawdown, @max_drawdown_pct = @p.max_drawdown

    # Thời gian nắm giữ trung bình (lệnh thắng vs thua) — xấp xỉ theo mã.
    first_buy = current_account.trades.side_buy.executed.group(:stock_id).minimum(:traded_at)
    sells = current_account.trades.side_sell.where(id: events.map(&:sell_trade_id)).index_by(&:id)
    holds = { win: [], loss: [] }
    events.each do |e|
      sell = sells[e.sell_trade_id]
      fb = sell && first_buy[sell.stock_id]
      next unless fb
      days = (sell.traded_at.to_date - fb.to_date).to_i
      (e.pnl >= 0 ? holds[:win] : holds[:loss]) << days
    end
    @avg_hold_win = holds[:win].any? ? (holds[:win].sum.to_f / holds[:win].size).round(1) : nil
    @avg_hold_loss = holds[:loss].any? ? (holds[:loss].sum.to_f / holds[:loss].size).round(1) : nil

    # Lịch P&L theo ngày (heatmap ~3 tháng gần nhất)
    @daily_pnl = @p.realized_series(:day) # { "YYYY-MM-DD" => pnl }
    @calendar_months = (0..2).map { |i| (Date.current.beginning_of_month - i.months) }.reverse
  end
end
