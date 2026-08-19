class CreateTrades < ActiveRecord::Migration[7.2]
  def change
    create_table :trades do |t|
      t.references :account, null: false, foreign_key: true
      t.references :stock, null: false, foreign_key: true
      t.integer :side, null: false, default: 0
      t.integer :quantity, null: false, default: 0
      t.decimal :price, precision: 15, scale: 2, null: false, default: 0
      t.datetime :traded_at, null: false
      t.decimal :fee, precision: 15, scale: 2, null: false, default: 0
      t.decimal :tax, precision: 15, scale: 2, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.date :settlement_date
      t.string :strategy_tag
      t.text :note

      t.timestamps
    end
    add_index :trades, :traded_at
    add_index :trades, :status
    add_index :trades, :side
    add_index :trades, :strategy_tag
  end
end
