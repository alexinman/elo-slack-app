class CreateGameTypes < ActiveRecord::Migration
  def up
    create_table :game_types do |t|
      t.text :team_id, null:false
      t.text :game_type, null:false

      t.timestamps null: false
    end

    add_column :players, :game_type_id, :integer
    add_foreign_key :players, :game_types, on_delete: :cascade

    Player.find_each do |player|
      game_type = GameType.where(team_id: player.team_id, game_type: player.attributes['game_type']).first_or_initialize
      game_type.save unless game_type.persisted?
      player.update_column(:game_type_id, game_type.id)
    end

    remove_column :players, :game_type
    change_column :players, :game_type_id, :integer, null: false
  end

  def down
    add_column :players, :game_type, :text

    Player.find_each do |player|
      game_type = GameType.find_by_id(player.game_type_id)
      player.update_column(:game_type, game_type.try(:game_type) || 'unknown')
    end

    remove_column :players, :game_type_id
    change_column :players, :game_type, :text, null: false
    drop_table :game_types
  end
end
