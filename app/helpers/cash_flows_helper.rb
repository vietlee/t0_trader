module CashFlowsHelper
  KIND_LABELS = {
    "deposit" => "Nạp tiền", "withdraw" => "Rút tiền", "dividend" => "Cổ tức",
    "interest" => "Lãi", "adjust" => "Điều chỉnh"
  }.freeze

  def cash_flow_kind_label(kind)
    KIND_LABELS[kind.to_s] || kind
  end

  def cash_flow_kind_options
    CashFlow.kinds.keys.map { |k| [cash_flow_kind_label(k), k] }
  end
end
