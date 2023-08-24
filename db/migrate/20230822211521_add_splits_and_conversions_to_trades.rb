class AddSplitsAndConversionsToTrades < ActiveRecord::Migration[7.0]
  def change
    add_column :trades, :split_new_shares, :decimal
    add_column :trades, :conversion_security_id, :integer
    add_column :trades, :conversion_new_shares, :decimal
  end
end
