class User < ApplicationRecord
  # :registerable cho phép tự đăng ký + đổi email/mật khẩu (không xác thực email).
  devise :database_authenticatable, :registerable, :rememberable, :validatable

  has_many :accounts, dependent: :destroy
  has_many :ai_insights, dependent: :destroy
  has_many :ai_messages, dependent: :destroy

  after_create :ensure_primary_account

  # Single-account-per-user (mỗi user 1 danh mục chính).
  def primary_account
    accounts.order(:id).first
  end

  private

  def ensure_primary_account
    accounts.create!(name: "Danh mục chính", broker: "VNDirect") if accounts.empty?
  end
end
