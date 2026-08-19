class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate_user!
  layout :resolve_layout

  helper_method :current_account

  def resolve_layout
    devise_controller? ? "auth" : "application"
  end

  private

  def current_account
    return unless user_signed_in?

    @current_account ||= current_user.primary_account ||
                         current_user.accounts.create!(name: "Danh mục chính", broker: "VNDirect")
  end

  def portfolio(as_of: Date.current)
    @portfolio ||= {}
    @portfolio[as_of] ||= PortfolioCalculator.new(current_account, as_of: as_of)
  end
  helper_method :portfolio
end
