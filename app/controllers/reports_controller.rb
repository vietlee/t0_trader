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
  end
end
