class CreateWatchlistItems < ActiveRecord::Migration[7.2]
  def change
    create_table :watchlist_items do |t|
      t.references :account, null: false, foreign_key: true
      t.references :stock, null: false, foreign_key: true
      t.decimal :target_buy_price, precision: 15, scale: 2
      t.string :note

      t.timestamps
    end
    add_index :watchlist_items, [:account_id, :stock_id], unique: true
  end
end
