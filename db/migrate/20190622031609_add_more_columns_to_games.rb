class AddMoreColumnsToGames < ActiveRecord::Migration[4.2]
  def up
    add_column :games, :team_id, :text
    add_column :games, :player_one_user_id, :text
    add_column :games, :player_two_user_id, :text
    add_column :games, :game_type_id, :integer
    add_column :games, :team_size, :integer

    execute <<-SQL
      update games
      set team_id            = (select team_id from players where players.id = games.player_one_id),
          player_one_user_id = (select user_id from players where players.id = games.player_one_id),
          player_two_user_id = (select user_id from players where players.id = games.player_two_id),
          game_type_id       = (select game_type_id from players where players.id = games.player_one_id),
          team_size          = (select team_size from players where players.id = games.player_one_id);
    SQL

    change_column :games, :team_id, :text, null: false
    change_column :games, :player_one_user_id, :text, null: false
    change_column :games, :player_two_user_id, :text, null: false
    change_column :games, :game_type_id, :integer, null: false
    change_column :games, :team_size, :integer, null: false, default: 1

    add_foreign_key :games, :game_types, on_delete: :cascade
  end

  def down
    remove_column :games, :team_id
    remove_column :games, :player_one_user_id
    remove_column :games, :player_two_user_id
    remove_column :games, :game_type_id
    remove_column :games, :team_size
  end
end
