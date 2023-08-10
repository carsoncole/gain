class CreateTrades < ActiveRecord::Migration[7.0]
  def change
    create_table :trades do |t|
      t.date :date
      t.references :account, null: false, foreign_key: true
      t.references :security, null: false, foreign_key: true
      t.decimal :price, precision: 15, scale: 5
      t.decimal :quantity, precision: 15, scale: 2
      t.decimal :fee, precision: 15, scale: 2, default: 0
      t.decimal :other, precision: 15, scale: 2, default: 0
      t.decimal :amount, precision: 15, scale: 2
      t.decimal :quantity_balance, precision: 15, scale: 5, default: 0
      t.decimal :cost_balance, precision: 15, scale: 2
      t.decimal :quantity_tax_balance, precision: 15, scale: 5, default: 0
      t.decimal :current_cost_balance, precision: 15, scale: 2
      t.string :trade_type

      t.timestamps
    end

    add_index :trades, [:account_id, :security_id]
  end
end
