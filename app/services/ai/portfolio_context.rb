module Ai
  # Dựng bản tóm tắt danh mục (text) để đưa vào prompt cho AI.
  class PortfolioContext
    def self.build(account)
      new(account).build
    end

    def initialize(account)
      @account = account
      @p = PortfolioCalculator.new(account)
    end

    def build
      s = @p.stats
      lines = []
      lines << "## Tổng quan danh mục (đơn vị: VND)"
      lines << "- Vốn đã nạp: #{fmt @p.capital_in}"
      lines << "- Tiền mặt: #{fmt @p.cash}"
      lines << "- Giá trị cổ phiếu đang giữ: #{fmt @p.market_value}"
      lines << "- NAV (tổng tài sản): #{fmt @p.nav}"
      lines << "- Lời/lỗ đã hiện thực: #{fmt @p.realized_total}"
      lines << "- Lời/lỗ chưa hiện thực: #{fmt @p.unrealized_total}"
      lines << "- Tỷ suất lợi nhuận trên vốn: #{@p.total_return_pct}%"
      lines << "- Tổng phí+thuế đã trả: #{fmt @p.fees_total}"
      lines << ""
      lines << "## Thống kê giao dịch"
      lines << "- Số lệnh đã đóng: #{s[:closed_count]} (thắng #{s[:win_count]}, thua #{s[:loss_count]})"
      lines << "- Tỷ lệ thắng: #{s[:win_rate]}% · Profit factor: #{s[:profit_factor]}"
      lines << "- Lãi TB/lệnh thắng: #{fmt s[:avg_win]} · Lỗ TB/lệnh thua: #{fmt s[:avg_loss]}"
      lines << "- Lệnh lời nhất: #{fmt s[:best]} · Lệnh lỗ nhất: #{fmt s[:worst]}"
      lines << ""
      lines << "## Vị thế đang mở"
      if @p.positions.any?
        @p.positions.each do |pos|
          lines << "- #{pos.stock.symbol}: #{pos.quantity} CP, giá vốn #{fmt pos.avg_cost}, giá TT #{fmt pos.market_price}, " \
                   "lãi/lỗ #{fmt pos.unrealized} (#{pos.unrealized_pct}%); bán được hôm nay #{pos.available_qty}, đang về #{pos.pending_qty}"
        end
      else
        lines << "- (không có)"
      end
      lines << ""
      lines << "## Lịch sử lệnh đã đóng gần đây (tối đa 25)"
      closed = closed_trades_detail.first(25)
      if closed.any?
        closed.each do |c|
          lines << "- #{c[:date]} #{c[:symbol]} | KL #{c[:qty]} | lời/lỗ #{fmt c[:pnl]} | giữ #{c[:hold]} ngày | nhãn: #{c[:tag]}"
        end
      else
        lines << "- (chưa có lệnh đóng)"
      end
      lines.join("\n")
    end

    private

    # Ghép mua-bán để mô tả từng lệnh đóng (theo lệnh bán).
    def closed_trades_detail
      sells = @account.trades.side_sell.executed.includes(:stock).order(traded_at: :desc)
      buys_first = @account.trades.side_buy.executed.group(:stock_id).minimum(:traded_at)
      @p.realized_events.sort_by { |e| -e.traded_at.to_i }.map do |e|
        sell = sells.detect { |t| t.id == e.sell_trade_id }
        hold = if sell && buys_first[sell.stock_id]
          (sell.traded_at.to_date - buys_first[sell.stock_id].to_date).to_i
        end
        {
          date: e.date.strftime("%d/%m/%y"), symbol: e.stock&.symbol, qty: e.quantity,
          pnl: e.pnl, hold: hold || "?", tag: sell&.strategy_tag.presence || "-"
        }
      end
    end

    def fmt(n)
      return "0" if n.nil?

      ActiveSupport::NumberHelper.number_to_delimited(n.to_d.round(0).to_i, delimiter: ".")
    end
  end
end
