class CreateAiMessages < ActiveRecord::Migration[7.2]
  def change
    create_table :ai_messages do |t|
      t.integer :role, null: false, default: 0
      t.text :content

      t.timestamps
    end
    add_index :ai_messages, :created_at
  end
end
