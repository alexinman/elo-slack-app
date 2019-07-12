class Player < ActiveRecord::Base
  belongs_to :game_type

  after_initialize :store_current_rating

  scope :for_user_id, ->(user_id) do
    where('user_id ilike ?', "%#{user_id}%")
  end

  def games
    return @games unless @games.nil?
    return [] unless self.id.present?
    player_one = Game.arel_table[:player_one_id].eq(self.id)
    player_two = Game.arel_table[:player_two_id].eq(self.id)
    @games = Game.where(player_one.or(player_two))
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
    player_one = Game.arel_table[:player_one_id].eq(self.id)
    player_two = Game.arel_table[:player_two_id].eq(self.id)
    player_one_wins = player_one.and(Game.arel_table[:result].eq(1))
    player_two_wins = player_two.and(Game.arel_table[:result].eq(0))
    Game.where(player_one_wins.or(player_two_wins)).count
  end

  def number_of_losses
    player_one = Game.arel_table[:player_one_id].eq(self.id)
    player_two = Game.arel_table[:player_two_id].eq(self.id)
    player_one_loses = player_one.and(Game.arel_table[:result].eq(0))
    player_two_loses = player_two.and(Game.arel_table[:result].eq(1))
    Game.where(player_one_loses.or(player_two_loses)).count
  end

  def number_of_ties
    return @ties if defined? @ties
    player_one = Game.arel_table[:player_one_id].eq(self.id)
    player_two = Game.arel_table[:player_two_id].eq(self.id)
    @ties = Game.where(player_one.or(player_two)).where(result: 0.5).count
  end

  def nemesis
    return @nemesis if defined? @nemesis
    @nemesis = team_size == 2 ? doubles_nemesis : singles_nemesis
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
    singles_nemesis
  end

  def store_current_rating
    @rating_before = self.rating
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
