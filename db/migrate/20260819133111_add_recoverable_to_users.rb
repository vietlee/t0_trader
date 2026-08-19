class AddRecoverableToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :reset_password_token, :string unless column_exists?(:users, :reset_password_token)
    add_index :users, :reset_password_token, unique: true unless index_exists?(:users, :reset_password_token)
    add_column :users, :reset_password_sent_at, :datetime unless column_exists?(:users, :reset_password_sent_at)
  end
end
