class AiMessage < ApplicationRecord
  enum :role, { user: 0, assistant: 1, system: 2 }, prefix: true

  validates :content, presence: true

  scope :chronological, -> { order(:created_at, :id) }
  scope :conversation, -> { where.not(role: :system).chronological }
end
