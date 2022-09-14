namespace :elo do
  desc "fixup ratings"
  task fixup_ratings: :environment do
    elo_players = Hash.new { |h,k| h[k] = Elo::Player.new }
    Game.order(created_at: :asc).each do |game|
      elo_game = elo_players[game.player_one_id].versus elo_players[game.player_two_id]
      elo_game.result = game.result
    end
    elo_players.each do |id, elo_player|
      Player.where(id: id).update_all(rating: elo_player.rating)
    end
    Player.joins('LEFT OUTER JOIN games ON games.player_one_id = players.id OR games.player_two_id = players.id').where(games: {id: nil}).delete_all
  end
end
