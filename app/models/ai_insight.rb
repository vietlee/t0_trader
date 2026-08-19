class AiInsight < ApplicationRecord
  belongs_to :user

  enum :kind, { journal: 0, weekly: 1, pattern: 2, risk: 3 }, prefix: true
  enum :status, { queued: 0, processing: 1, done: 2, failed: 3 }, prefix: true

  scope :recent, -> { order(created_at: :desc) }

  KIND_LABELS = {
    "journal" => "Phân tích nhật ký",
    "weekly"  => "Tổng kết kỳ",
    "pattern" => "Phát hiện thói quen",
    "risk"    => "Kỷ luật & quản trị vốn"
  }.freeze

  def label
    KIND_LABELS[kind] || kind
  end
end
