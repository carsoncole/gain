class RemoveQuantityTaxBalanceFromTrades < ActiveRecord::Migration[7.0]
  def change
    remove_column :trades, :quantity_tax_balance, precision: 15, scale: 5, default: 0
    remove_column :trades, :cost_tax_balance, precision: 15, scale: 2
  end
end
