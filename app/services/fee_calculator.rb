# Tính phí giao dịch + thuế bán theo biểu phí (mỗi user chỉnh trong Settings).
class FeeCalculator
  DEFAULT_RATES = {
    buy_fee_rate:  User::SETTING_DEFAULTS["buy_fee_rate"],
    sell_fee_rate: User::SETTING_DEFAULTS["sell_fee_rate"],
    sell_tax_rate: User::SETTING_DEFAULTS["sell_tax_rate"]
  }.freeze

  # side: "buy"/"sell". Trả về { fee:, tax:, gross: } (VND, làm tròn).
  def self.for(side:, quantity:, price:, rates: DEFAULT_RATES)
    gross = quantity.to_i * price.to_d
    side = side.to_s

    fee_rate = side == "sell" ? rates[:sell_fee_rate] : rates[:buy_fee_rate]
    tax_rate = side == "sell" ? rates[:sell_tax_rate] : 0

    {
      gross: gross,
      fee: (gross * fee_rate.to_d).round(0),
      tax: (gross * tax_rate.to_d).round(0)
    }
  end
end
