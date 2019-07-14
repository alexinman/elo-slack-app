class Player < ActiveRecord::Base
  belongs_to :game_type

  after_initialize :store_current_rating

  scope :for_user_id, ->(user_id) do
    where('user_id ilike ?', "%#{user_id}%")
  end

  def games
    return Game.none unless id.present?
    Game.for_user_id(user_id).where(team_id: team_id, game_type_id: game_type_id, team_size: team_size)
  end

  def won_against(other_player, logged_by_user_id)
    log_game(other_player, logged_by_user_id, :wins_from)
  end

  def tied_with(other_player, logged_by_user_id)
    log_game(other_player, logged_by_user_id, :plays_draw)
  end

  def elo_player
    @elo_player ||= Elo::Player.new(rating: rating, games_played: games.count)
  end

  def team_tag
    user_id.split("-").map { |id| "<#{id}>" }.join(" and ")
  end

  def doubles?
    team_size == 2
  end

  def rating_change
    sprintf("%+d", self.rating - @rating_before)
  end

  def number_of_wins
    rel = Game.where(team_id: team_id, team_size: team_size, game_type_id: game_type_id)
    rel = rel.where('(player_one_user_id ilike ? and result = 1) OR (player_two_user_id ilike ? and result = 0)', "%#{user_id}%", "%#{user_id}%")
    rel.count
  end

  def number_of_losses
    rel = Game.where(team_id: team_id, team_size: team_size, game_type_id: game_type_id)
    rel = rel.where('(player_one_user_id ilike ? and result = 0) OR (player_two_user_id ilike ? and result = 1)', "%#{user_id}%", "%#{user_id}%")
    rel.count
  end

  def number_of_ties
    return @ties if defined? @ties
    rel = Game.where(team_id: team_id, team_size: team_size, game_type_id: game_type_id)
    rel = rel.where('(player_one_user_id ilike ? OR player_two_user_id ilike ?) and result = 0.5', "%#{user_id}%", "%#{user_id}%")
    @ties = rel.count
  end

  def nemesis
    return @nemesis if defined? @nemesis
    individual = user_id.split('-').size == 1
    @nemesis = individual && team_size == 2 ? doubles_nemesis : singles_nemesis
  end

  private

  def singles_nemesis
    Player.find_by_sql([<<-SQL, team_id: team_id, player_id: id, game_type_id: game_type_id, team_size: team_size]).first.try(:team_tag)
      WITH player_games AS (
        SELECT id,
          player_one_id AS opponent_id,
          result = 0 AS win
        FROM games
        WHERE player_two_id = :player_id
          AND team_id = :team_id
          AND game_type_id = :game_type_id
          AND team_size = :team_size
        UNION 
        SELECT id,
          player_two_id AS opponent_id,
          result = 1 as win
        FROM games
        WHERE player_one_id = :player_id
          AND team_id = :team_id
          AND game_type_id = :game_type_id
          AND team_size = :team_size)
      SELECT * FROM players
      WHERE id IN (SELECT opponent_id
                   FROM player_games
                   GROUP BY opponent_id
                   HAVING count(opponent_id) > 4
                   ORDER BY sum(win::integer)::float / count(opponent_id)::float ASC
                   LIMIT 1);
    SQL
  end

  def doubles_nemesis
    Player.find_by_sql([<<-SQL, team_id: team_id, user_id: user_id, game_type_id: game_type_id, team_size: team_size]).first.try(:team_tag)
      WITH player_games AS (
        SELECT id,
          regexp_split_to_table(player_one_user_id, '-') AS opponent_user_id,
          result = 0 AS win
        FROM games
        WHERE player_two_user_id ilike '%' || :user_id || '%'
          AND team_id = :team_id
          AND game_type_id = :game_type_id
          AND team_size = :team_size
        UNION 
        SELECT id,
          regexp_split_to_table(player_two_user_id, '-') AS opponent_user_id,
          result = 1 as win
        FROM games
        WHERE player_one_user_id ilike '%' || :user_id || '%'
          AND team_id = :team_id
          AND game_type_id = :game_type_id
          AND team_size = :team_size)
      SELECT opponent_user_id as user_id
      FROM player_games
      GROUP BY opponent_user_id
      HAVING count(opponent_user_id) > 4
      ORDER BY sum(win::integer)::float / count(opponent_user_id)::float ASC
      LIMIT 1;
    SQL
  end

  def store_current_rating
    @rating_before = self.rating rescue 1000
  end

  def log_game(other_player, logged_by_user_id, result)
    raise ArgumentError, 'other_player is for different game_type' unless self.game_type_id == other_player.game_type_id
    elo_game = elo_player.send(result, other_player.elo_player)
    Game.create!(logged_by_user_id: logged_by_user_id, player_one: self, player_two: other_player, result: elo_game.result)
    @games = nil
    self.rating = elo_player.rating
    other_player.rating = other_player.elo_player.rating
    other_player.save! && save!
  end
end
