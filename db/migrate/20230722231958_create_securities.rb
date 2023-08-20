class CreateSecurities < ActiveRecord::Migration[7.0]
  def change
    create_table :securities do |t|
      t.string :name
      t.string :symbol
      t.integer :currency_id
      t.references :user, null: false

      t.timestamps
    end
  end
end
