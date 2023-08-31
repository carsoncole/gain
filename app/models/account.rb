class Account < ApplicationRecord
  belongs_to :currency
  belongs_to :user
  has_many :trades, dependent: :destroy
  has_many :gain_losses
  has_many :lots, dependent: :destroy

  validates :title, :number, presence: true

  def positions(date=nil)
    Position.all(self, date)
  end

  def last_trade(security)
    trades.where(security: security).where("id IS NOT NULL").order(:date, :id).last
  end
end
