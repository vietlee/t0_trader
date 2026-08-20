class SymbolsController < ApplicationController
  # Gợi ý mã khi gõ (autocomplete).
  def search
    results = SymbolRef.search(params[:q].to_s, limit: 8)
    render json: results.map { |s| { symbol: s.symbol, name: s.name, exchange: s.exchange } }
  end
end
