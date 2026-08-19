class CreateAlertLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :alert_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.references :stock, null: false, foreign_key: true
      t.string :direction, null: false # "profit" / "loss"
      t.decimal :pct, precision: 8, scale: 2
      t.timestamps
    end
    add_index :alert_logs, [:user_id, :stock_id, :direction, :created_at]
  end
end
