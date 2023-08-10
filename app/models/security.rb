class Security < ApplicationRecord
  belongs_to :currency
  has_many :trades

  validates :name, :symbol, presence: true

  before_save { |security| security.symbol = security.symbol.upcase }
end
