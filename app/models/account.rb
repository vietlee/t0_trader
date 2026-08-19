class Account < ApplicationRecord
  belongs_to :user
  has_many :trades, dependent: :destroy
  has_many :cash_flows, dependent: :destroy

  validates :name, presence: true
end
