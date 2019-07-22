class RenameColumns < ActiveRecord::Migration
  def change
    rename_column :game_types, :game_type, :game_name

    rename_column :players, :team_id, :slack_team_id
    rename_column :games, :team_id, :slack_team_id
    rename_column :game_types, :team_id, :slack_team_id

    rename_column :players, :user_id, :slack_user_id
    rename_column :games, :logged_by_user_id, :logged_by_slack_user_id
    rename_column :games, :player_one_user_id, :player_one_slack_user_id
    rename_column :games, :player_two_user_id, :player_two_slack_user_id
  end
end
