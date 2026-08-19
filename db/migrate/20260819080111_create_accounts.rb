class CreateAccounts < ActiveRecord::Migration[7.2]
  def change
    create_table :accounts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false, default: "Danh mục chính"
      t.string :broker, default: "VNDirect"

      t.timestamps
    end
  end
end
