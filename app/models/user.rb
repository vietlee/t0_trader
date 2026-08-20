class User < ApplicationRecord
  # :registerable cho phép tự đăng ký + đổi email/mật khẩu (không xác thực email).
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable

  has_many :accounts, dependent: :destroy
  has_many :ai_insights, dependent: :destroy
  has_many :ai_messages, dependent: :destroy
  has_many :alert_logs, dependent: :destroy

  after_create :ensure_primary_account

  # Cấu hình riêng của từng user (biểu phí, model AI). Lưu trong jsonb `preferences`.
  SETTING_DEFAULTS = {
    "buy_fee_rate"       => 0.0015,  # 0.15%
    "sell_fee_rate"      => 0.0015,  # 0.15%
    "sell_tax_rate"      => 0.0010,  # 0.10%
    "ai_model"           => "claude-sonnet-5",
    "ai_enabled"         => true,
    "alert_enabled"      => false,   # bật email cảnh báo
    "alert_threshold_pct" => 5.0,    # ngưỡng % lời/lỗ để cảnh báo
    "risk_per_trade_pct" => 2.0,     # % vốn rủi ro mỗi lệnh (position sizing)
    "max_position_pct"   => 20.0,    # cảnh báo khi 1 mã > % NAV
    "max_daily_trades"   => 0,       # chặn overtrading (0 = tắt)
    "ai_review_frequency" => "off"   # off / weekly / monthly — AI review tự gửi email
  }.freeze

  def pref(key)
    key = key.to_s
    prefs = preferences || {}
    prefs.key?(key) ? prefs[key] : SETTING_DEFAULTS[key]
  end

  def fee_rates
    {
      buy_fee_rate:  pref("buy_fee_rate").to_f,
      sell_fee_rate: pref("sell_fee_rate").to_f,
      sell_tax_rate: pref("sell_tax_rate").to_f
    }
  end

  def ai_model
    pref("ai_model").presence || SETTING_DEFAULTS["ai_model"]
  end

  def ai_enabled?
    !!pref("ai_enabled")
  end

  def alert_enabled?
    !!pref("alert_enabled")
  end

  def alert_threshold_pct
    pref("alert_threshold_pct").to_f
  end

  def risk_per_trade_pct = pref("risk_per_trade_pct").to_f
  def max_position_pct   = pref("max_position_pct").to_f
  def max_daily_trades   = pref("max_daily_trades").to_i
  def ai_review_frequency = pref("ai_review_frequency").to_s

  def update_preferences(hash)
    self.preferences = (preferences || {}).merge(hash.stringify_keys)
    save!
  end

  # Single-account-per-user (mỗi user 1 danh mục chính).
  def primary_account
    accounts.order(:id).first
  end

  private

  def ensure_primary_account
    accounts.create!(name: "Danh mục chính", broker: "VNDirect") if accounts.empty?
  end
end
