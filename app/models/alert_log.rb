class AlertLog < ApplicationRecord
  belongs_to :user
  belongs_to :stock

  COOLDOWN = 20.hours

  # Đã gửi cảnh báo cho (user, stock, direction) trong thời gian cooldown chưa?
  def self.recently_alerted?(user, stock, direction)
    where(user: user, stock: stock, direction: direction)
      .where("created_at > ?", COOLDOWN.ago).exists?
  end
end
