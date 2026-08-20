class CreateRiskTargets < ActiveRecord::Migration[7.2]
  def change
    create_table :risk_targets do |t|
      t.references :account, null: false, foreign_key: true
      t.references :stock, null: false, foreign_key: true
      t.decimal :stop_loss, precision: 15, scale: 2
      t.decimal :take_profit, precision: 15, scale: 2
      t.string :note

      t.timestamps
    end
    add_index :risk_targets, [:account_id, :stock_id], unique: true
  end
end
