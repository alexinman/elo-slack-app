class Player < ActiveRecord::Base
  after_initialize :init_elo_player

  attr_reader :elo_player

  def games
    return @games unless @games.nil?
    return [] unless self.id.present?
    player_one = Game.arel_table[:player_one_id].eq(self.id)
    player_two = Game.arel_table[:player_two_id].eq(self.id)
    @games = Game.where(player_one.or(player_two))
  end

  def beats(other_player, logged_by_user_id)
    transaction do
      elo_game = elo_player.wins_from(other_player.elo_player)
      Game.create!(logged_by_user_id: logged_by_user_id, player_one: self, player_two: other_player, result: elo_game.result)
      @games = nil
      self.rating = elo_player.rating
      other_player.rating = other_player.elo_player.rating
      other_player.save! && save!
    end
  end

  private

  def init_elo_player
    @elo_player = Elo::Player.new(rating: rating, games_played: games.count)
  end
end
