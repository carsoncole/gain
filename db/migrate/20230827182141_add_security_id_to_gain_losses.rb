class AddSecurityIdToGainLosses < ActiveRecord::Migration[7.0]
  def change
    add_column :gain_losses, :security_id, :integer
  end
end
