class CreateGames < ActiveRecord::Migration
  def change
    create_table :games do |t|
      t.text :logged_by_user_id, null: false
      t.integer :player_one_id, null: false
      t.integer :player_two_id, null: false
      t.integer :result, null: false

      t.timestamps null: false
    end
    add_foreign_key :games, :players, column: :player_one_id, on_delete: :cascade
    add_foreign_key :games, :players, column: :player_two_id, on_delete: :cascade
  end
end
