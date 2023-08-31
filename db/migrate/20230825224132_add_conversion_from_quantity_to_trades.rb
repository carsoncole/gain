class AddConversionFromQuantityToTrades < ActiveRecord::Migration[7.0]
  def change
    add_column :trades, :conversion_from_quantity, :decimal
    rename_column :trades, :conversion_new_shares, :conversion_to_quantity
    add_column :trades, :conversion_from_security_id, :integer
    rename_column :trades, :conversion_security_id, :conversion_to_security_id
  end
end
