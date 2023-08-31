class Account < ApplicationRecord
  belongs_to :currency
  belongs_to :user
  has_many :trades, dependent: :destroy
  has_many :gain_losses
  has_many :lots, dependent: :destroy

  validates :title, :number, presence: true

  def holdings_as_security_ids
    trades.group(:security_id).map{|t| t.security_id }
  end

  def positions(date=nil)
    Position.all(self, date)
  end
end
