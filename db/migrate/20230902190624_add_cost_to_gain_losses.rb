class AddCostToGainLosses < ActiveRecord::Migration[7.0]
  def change
    add_column :gain_losses, :cost, :decimal, precision: 15, scale: 2
    add_column :gain_losses, :proceeds, :decimal, precision: 15, scale: 2
    add_column :gain_losses, :purchase_date, :date
  end
end
