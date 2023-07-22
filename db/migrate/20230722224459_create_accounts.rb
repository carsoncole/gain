class CreateAccounts < ActiveRecord::Migration[7.0]
  def change
    create_table :accounts do |t|
      t.string :title
      t.string :number
      t.references :currency

      t.timestamps
    end
  end
end
