class GainLoss < ApplicationRecord
  belongs_to :trade
  belongs_to :security
  belongs_to :account
  belongs_to :source_trade, class_name: 'Trade'

  validates :date, :quantity, :amount, presence: true

  scope :short_term, -> { where(("julianday(date) - julianday(purchase_date) < 366"))}
  scope :long_term, -> { where(("julianday(date) - julianday(purchase_date) > 365"))}
end
