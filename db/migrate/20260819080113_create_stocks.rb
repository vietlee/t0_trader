class CreateStocks < ActiveRecord::Migration[7.2]
  def change
    create_table :stocks do |t|
      t.string :symbol, null: false
      t.string :name
      t.string :exchange, default: "HOSE"
      t.decimal :current_price, precision: 15, scale: 2
      t.datetime :price_updated_at
      t.string :sector

      t.timestamps
    end
    add_index :stocks, :symbol, unique: true
  end
end
