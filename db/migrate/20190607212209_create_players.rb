class CreatePlayers < ActiveRecord::Migration[4.2]
  def change
    create_table :players do |t|
      t.text :team_id, null: false
      t.text :user_id, null: false
      t.text :game_type, null: false
      t.integer :rating, null: false, default: 1000

      t.timestamps null: false
    end
  end
end
