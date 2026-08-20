class Account < ApplicationRecord
  belongs_to :user
  has_many :trades, dependent: :destroy
  has_many :cash_flows, dependent: :destroy
  has_many :risk_targets, dependent: :destroy
  has_many :watchlist_items, dependent: :destroy

  validates :name, presence: true
end
