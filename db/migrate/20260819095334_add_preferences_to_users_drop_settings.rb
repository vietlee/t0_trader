class AddPreferencesToUsersDropSettings < ActiveRecord::Migration[7.2]
  def up
    add_column :users, :preferences, :jsonb, default: {}, null: false
    drop_table :settings, if_exists: true
  end

  def down
    remove_column :users, :preferences
    create_table :settings do |t|
      t.string :key, null: false
      t.jsonb :value, default: {}
      t.timestamps
    end
    add_index :settings, :key, unique: true
  end
end
