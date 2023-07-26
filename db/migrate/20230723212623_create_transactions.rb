class CreateTransactions < ActiveRecord::Migration[7.0]
  def change
    create_table :transactions do |t|
      t.date :date
      t.references :account, null: false, foreign_key: true
      t.references :security, null: false, foreign_key: true
      t.decimal :price, precision: 15, scale: 5
      t.decimal :quantity, precision: 15, scale: 2
      t.decimal :fee, precision: 15, scale: 2, default: 0
      t.decimal :other, precision: 15, scale: 2, default: 0
      t.decimal :amount, precision: 15, scale: 2
      t.decimal :security_balance, precision: 15, scale: 5, default: 0
      t.decimal :cash_balance, precision: 15, scale: 2
      t.string :transaction_type

      t.timestamps
    end
  end
end
