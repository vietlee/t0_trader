class CreateSymbolRefs < ActiveRecord::Migration[7.2]
  def change
    create_table :symbol_refs do |t|
      t.string :symbol, null: false
      t.string :name
      t.string :exchange

      t.timestamps
    end
    add_index :symbol_refs, :symbol, unique: true
  end
end
