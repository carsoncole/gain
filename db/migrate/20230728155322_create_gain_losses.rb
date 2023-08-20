class CreateGainLosses < ActiveRecord::Migration[7.0]
  def change
    create_table :gain_losses do |t|
      t.references :account, null: false, foreign_key: true
      t.date :date
      t.references :trade, null: false
      t.references :source_trade
      t.decimal :quantity, precision: 15, scale: 2
      t.decimal :amount, precision: 15, scale: 2

      t.timestamps
    end
  end
end
