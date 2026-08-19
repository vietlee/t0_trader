class CreateAiInsights < ActiveRecord::Migration[7.2]
  def change
    create_table :ai_insights do |t|
      t.integer :kind, null: false, default: 0
      t.date :period_start
      t.date :period_end
      t.text :content
      t.string :ai_model
      t.integer :status, null: false, default: 0
      t.jsonb :context, default: {}

      t.timestamps
    end
    add_index :ai_insights, :kind
    add_index :ai_insights, :created_at
  end
end
