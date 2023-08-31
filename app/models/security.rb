class Security < ApplicationRecord
  belongs_to :user
  belongs_to :currency
  has_many :trades
  has_many :gain_losses
  has_many :lots

  validates :name, :symbol, presence: true

  before_save { |security| security.symbol = security.symbol.upcase }

end
