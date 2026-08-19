class CreateCashFlows < ActiveRecord::Migration[7.2]
  def change
    create_table :cash_flows do |t|
      t.references :account, null: false, foreign_key: true
      t.integer :kind, null: false, default: 0
      t.decimal :amount, precision: 18, scale: 2, null: false, default: 0
      t.date :occurred_on, null: false
      t.string :note

      t.timestamps
    end
    add_index :cash_flows, :occurred_on
    add_index :cash_flows, :kind
  end
end
