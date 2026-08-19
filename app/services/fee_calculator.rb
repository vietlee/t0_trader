# Tính phí giao dịch + thuế bán theo biểu phí VNDirect (chỉnh trong Settings).
class FeeCalculator
  # side: "buy"/"sell" (hoặc symbol). Trả về { fee:, tax:, gross: } (VND, làm tròn).
  def self.for(side:, quantity:, price:, rates: Setting.fee_rates)
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
