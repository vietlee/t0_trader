class AddUserToAiTables < ActiveRecord::Migration[7.2]
  def change
    add_reference :ai_insights, :user, foreign_key: true, index: true
    add_reference :ai_messages, :user, foreign_key: true, index: true
  end
end
