class CreateLots < ActiveRecord::Migration[7.0]
  def change
    create_table :lots do |t|
      t.references :account, null: false, foreign_key: true
      t.references :security, null: false, foreign_key: true
      t.date :date
      t.integer :trade_id
      t.decimal :quantity, precision: 15, scale: 2
      t.decimal :amount, precision: 15, scale: 2
      t.timestamps
    end
  end
end
