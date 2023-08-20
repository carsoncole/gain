class GainLoss < ApplicationRecord
  belongs_to :trade
  belongs_to :account
  belongs_to :source_trade, class_name: 'Trade'

  validates :date, :quantity, :amount, presence: true

  # before_destroy :reverse_accounting!

  def reverse_accounting!
    source_trade.reload.update!(
      quantity_tax_balance: source_trade.quantity_tax_balance + quantity,
      cost_tax_balance: source_trade.cost_tax_balance + (source_trade.cost_per_unit * quantity),
      is_recalc: true
      )
  end
end
