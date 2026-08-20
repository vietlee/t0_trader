class AddActiveToWatchlistItems < ActiveRecord::Migration[7.2]
  def change
    add_column :watchlist_items, :active, :boolean, null: false, default: true
  end
end
