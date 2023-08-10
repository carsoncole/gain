class CreateGainLosses < ActiveRecord::Migration[7.0]
  def change
    create_table :gain_losses do |t|
      t.references :account, null: false, foreign_key: true
      t.date :date
      t.references :security, null: false, foreign_key: true
      t.references :trade, null: false, foreign_key: true

      t.timestamps
    end
  end
end
