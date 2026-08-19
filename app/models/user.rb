class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :rememberable, :validatable

  has_many :accounts, dependent: :destroy

  # Single-user app: convenience accessor to the primary portfolio.
  def primary_account
    accounts.order(:id).first
  end
end
