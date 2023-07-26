class Security < ApplicationRecord
  belongs_to :currency
  has_many :transactions

  validates :name, :symbol, presence: true

  before_save { |security| security.symbol = security.symbol.upcase }
end
