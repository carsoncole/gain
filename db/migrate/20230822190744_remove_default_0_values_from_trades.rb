class RemoveDefault0ValuesFromTrades < ActiveRecord::Migration[7.0]
  def change
    change_column_default(:trades, :quantity_balance, from: 0, to: nil)
    change_column_default(:trades, :quantity_tax_balance, from: 0, to: nil)
    change_column_default(:trades, :fee, from: 0, to: nil)
    change_column_default(:trades, :other, from: 0, to: nil)
  end
end
