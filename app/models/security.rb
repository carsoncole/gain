class Security < ApplicationRecord
  belongs_to :user
  belongs_to :currency
  has_many :trades

  validates :name, :symbol, presence: true

  before_save { |security| security.symbol = security.symbol.upcase }

  def splits(account)
    trades.splits.where(account_id: account.id)
  end

end
