class Account < ApplicationRecord
  belongs_to :currency
  belongs_to :user
  has_many :trades, dependent: :destroy
  has_many :gain_losses
  validates :title, :number, presence: true


  def holdings_as_security_ids
    trades.group(:security_id).map{|t| t.security_id }
  end
end
