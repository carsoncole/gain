class GainLoss < ApplicationRecord
  belongs_to :trade
  belongs_to :security
  belongs_to :account
  belongs_to :source_trade, class_name: 'Trade'

  validates :date, :quantity, :amount, presence: true

end
