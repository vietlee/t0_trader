class CreateTradingHolidays < ActiveRecord::Migration[7.2]
  def change
    create_table :trading_holidays do |t|
      t.date :holiday_on, null: false
      t.string :name

      t.timestamps
    end
    add_index :trading_holidays, :holiday_on, unique: true
  end
end
