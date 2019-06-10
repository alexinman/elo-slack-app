class Player < ActiveRecord::Base
  belongs_to :game_type

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

  private

  def log_game(other_player, logged_by_user_id, result)
    raise ArgumentError, 'other_player is for different game_type' unless self.game_type_id == other_player.game_type_id
    transaction do
      elo_game = elo_player.send(result, other_player.elo_player)
      Game.create!(logged_by_user_id: logged_by_user_id, player_one: self, player_two: other_player, result: elo_game.result)
      @games = nil
      self.rating = elo_player.rating
      other_player.rating = other_player.elo_player.rating
      other_player.save! && save!
    end
  end
end
