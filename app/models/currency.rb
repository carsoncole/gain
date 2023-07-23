class Currency < ApplicationRecord
  validates :name, :symbol, presence: true
  has_many :securities
  has_many :accounts
  before_save { |currency| currency.symbol = currency.symbol.upcase }
end
