# Nguồn sự thật cho dashboard/positions/reports.
# Duyệt toàn bộ giao dịch đã khớp theo thời gian, ghép FIFO để ra:
#   - vị thế mở (open lots) + giá vốn bình quân
#   - lời/lỗ đã thực hiện (realized) theo từng lần bán
#   - lời/lỗ chưa thực hiện (unrealized) theo giá hiện tại
#   - tiền mặt, vốn, NAV
#   - cổ phiếu BÁN ĐƯỢC HÔM NAY (đã về T+2) vs đang chờ về  ← lõi T+0
class PortfolioCalculator
  Position = Struct.new(
    :stock, :quantity, :avg_cost, :cost_basis, :market_price, :market_value,
    :unrealized, :unrealized_pct, :available_qty, :pending_qty, :pending_lots,
    keyword_init: true
  )

  RealizedEvent = Struct.new(
    :date, :traded_at, :stock, :quantity, :pnl, :sell_trade_id, keyword_init: true
  )

  attr_reader :account, :as_of

  def initialize(account, as_of: Date.current)
    @account = account
    @as_of = as_of.to_date
    compute!
  end

  # ---- Tổng hợp ----------------------------------------------------------

  def capital_in        = @capital_in                     # vốn đã bơm ròng
  def cash              = @cash                            # tiền mặt khả dụng
  def market_value      = positions.sum(&:market_value)   # giá trị cổ phiếu
  def nav               = cash + market_value             # tổng tài sản ròng
  def realized_total    = realized_events.sum(&:pnl)
  def unrealized_total  = positions.sum(&:unrealized)
  def net_pnl           = realized_total + unrealized_total
  def total_return_pct  = capital_in.positive? ? (net_pnl / capital_in * 100).round(2) : 0
  def fees_total        = @fees_total
  def invested_cost     = positions.sum(&:cost_basis)

  def positions       = @positions
  def realized_events = @realized_events

  # ---- Lời/lỗ theo kỳ ----------------------------------------------------

  def realized_between(from, to)
    from = from.to_date
    to = to.to_date
    realized_events.select { |e| e.date >= from && e.date <= to }.sum(&:pnl)
  end

  def pnl_for(range_key)
    from, to = range_bounds(range_key)
    realized_between(from, to)
  end

  # { "2026-08-01" => 1_234, ... } lời/lỗ realized gộp theo đơn vị thời gian
  def realized_series(granularity = :day)
    realized_events.group_by { |e| bucket_key(e.date, granularity) }
                   .transform_values { |evs| evs.sum(&:pnl) }
                   .sort.to_h
  end

  # Đường vốn: luỹ kế lời/lỗ realized theo ngày.
  def equity_curve
    running = 0.to_d
    realized_series(:day).map do |day, pnl|
      running += pnl
      [day, running]
    end.to_h
  end

  # ---- Thống kê hành vi --------------------------------------------------

  # Gộp realized theo từng lệnh bán -> 1 "trade đóng".
  def closed_trades
    realized_events.group_by(&:sell_trade_id).map do |_id, evs|
      { pnl: evs.sum(&:pnl), date: evs.first.date, stock: evs.first.stock }
    end
  end

  def stats
    closed = closed_trades
    wins = closed.select { |c| c[:pnl] > 0 }
    losses = closed.select { |c| c[:pnl] < 0 }
    {
      closed_count: closed.size,
      win_count: wins.size,
      loss_count: losses.size,
      win_rate: closed.any? ? (wins.size.to_f / closed.size * 100).round(1) : 0,
      avg_win: wins.any? ? (wins.sum { |c| c[:pnl] } / wins.size).round(0) : 0,
      avg_loss: losses.any? ? (losses.sum { |c| c[:pnl] } / losses.size).round(0) : 0,
      best: closed.map { |c| c[:pnl] }.max || 0,
      worst: closed.map { |c| c[:pnl] }.min || 0,
      profit_factor: profit_factor(wins, losses)
    }
  end

  # ---- Panel T+0 ---------------------------------------------------------
  # Mỗi mã: bán được bao nhiêu hôm nay, còn bao nhiêu đang về (kèm ngày).
  def t0_rows
    positions.select { |p| p.quantity.positive? }.map do |p|
      {
        stock: p.stock,
        total: p.quantity,
        available: p.available_qty,
        pending: p.pending_qty,
        pending_schedule: p.pending_lots
      }
    end.sort_by { |r| -r[:available] }
  end

  def total_available_qty = positions.sum(&:available_qty)
  def total_pending_qty   = positions.sum(&:pending_qty)

  private

  def compute!
    @fees_total = 0.to_d
    lots = Hash.new { |h, k| h[k] = [] }   # stock_id => [ {qty, price, fee_ps, settlement_date, traded_at} ]
    @realized_events = []

    executed_trades.each do |t|
      @fees_total += t.fee.to_d + t.tax.to_d
      if t.side_buy?
        fee_ps = t.quantity.positive? ? (t.fee.to_d / t.quantity) : 0
        lots[t.stock_id] << {
          qty: t.quantity, price: t.price.to_d, fee_ps: fee_ps,
          settlement_date: t.settlement_date, traded_at: t.traded_at
        }
      else
        match_sell(t, lots[t.stock_id])
      end
    end

    build_positions(lots)
    compute_cash
  end

  def match_sell(trade, queue)
    remaining = trade.quantity
    sell_fee_ps = trade.quantity.positive? ? ((trade.fee.to_d + trade.tax.to_d) / trade.quantity) : 0
    pnl_total = 0.to_d

    while remaining.positive? && queue.any?
      lot = queue.first
      matched = [remaining, lot[:qty]].min
      cost = (lot[:price] + lot[:fee_ps]) * matched
      proceeds = (trade.price.to_d - sell_fee_ps) * matched
      pnl_total += proceeds - cost
      lot[:qty] -= matched
      remaining -= matched
      queue.shift if lot[:qty] <= 0
    end

    @realized_events << RealizedEvent.new(
      date: trade.traded_at.to_date, traded_at: trade.traded_at,
      stock: stock_for(trade.stock_id), quantity: trade.quantity - remaining,
      pnl: pnl_total.round(0), sell_trade_id: trade.id
    )
  end

  def build_positions(lots)
    @positions = lots.filter_map do |stock_id, queue|
      qty = queue.sum { |l| l[:qty] }
      next if qty <= 0

      stock = stock_for(stock_id)
      cost_basis = queue.sum { |l| (l[:price] + l[:fee_ps]) * l[:qty] }
      avg_cost = cost_basis / qty
      price = stock&.current_price&.to_d
      market_value = price ? price * qty : cost_basis
      unrealized = price ? (price - avg_cost) * qty : 0

      available = queue.select { |l| l[:settlement_date] && l[:settlement_date] <= as_of }.sum { |l| l[:qty] }
      pending_lots = queue.select { |l| l[:settlement_date].nil? || l[:settlement_date] > as_of }
                          .map { |l| { qty: l[:qty], settlement_date: l[:settlement_date],
                                       sessions: l[:settlement_date] ? TradingCalendar.sessions_until(l[:settlement_date], from: as_of) : nil } }

      Position.new(
        stock: stock, quantity: qty, avg_cost: avg_cost.round(2), cost_basis: cost_basis.round(0),
        market_price: price, market_value: market_value.round(0),
        unrealized: unrealized.round(0),
        unrealized_pct: avg_cost.positive? && price ? ((price - avg_cost) / avg_cost * 100).round(2) : 0,
        available_qty: available, pending_qty: qty - available, pending_lots: pending_lots
      )
    end.sort_by { |p| -p.market_value }
  end

  def compute_cash
    trade_cash = executed_trades.sum { |t| t.cash_delta }
    flow_cash = cash_flows.sum { |f| f.cash_delta }
    @capital_in = cash_flows.sum { |f| f.capital_delta }
    @cash = flow_cash + trade_cash
  end

  # ---- Nạp dữ liệu -------------------------------------------------------

  def executed_trades
    @executed_trades ||= account.trades.executed
                                .where("traded_at <= ?", as_of.end_of_day)
                                .chronological.to_a
  end

  def cash_flows
    @cash_flows ||= account.cash_flows.where("occurred_on <= ?", as_of).to_a
  end

  def stocks_by_id
    @stocks_by_id ||= Stock.where(id: executed_trades.map(&:stock_id).uniq).index_by(&:id)
  end

  def stock_for(id) = stocks_by_id[id]

  # ---- Helpers -----------------------------------------------------------

  def profit_factor(wins, losses)
    gross_loss = losses.sum { |c| c[:pnl] }.abs
    return 0 if gross_loss.zero?

    (wins.sum { |c| c[:pnl] } / gross_loss).round(2)
  end

  def bucket_key(date, granularity)
    case granularity
    when :week  then date.beginning_of_week.to_s
    when :month then date.strftime("%Y-%m")
    when :year  then date.year.to_s
    else date.to_s
    end
  end

  def range_bounds(range_key)
    case range_key.to_sym
    when :day   then [as_of, as_of]
    when :week  then [as_of.beginning_of_week, as_of.end_of_week]
    when :month then [as_of.beginning_of_month, as_of.end_of_month]
    when :year  then [as_of.beginning_of_year, as_of.end_of_year]
    else [Date.new(2000, 1, 1), as_of]
    end
  end
end
