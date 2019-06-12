class Game < ActiveRecord::Base
  belongs_to :player_one, class_name: 'Player'
  belongs_to :player_two, class_name: 'Player'

  def opponent(player)
    raise ArgumentError, "player did not play in this game" unless [player_one_id, player_two_id].include? player.id
    player_one_id == player.id ? player_two : player_one
  end

  def result_for(player)
    raise ArgumentError, "player did not play in this game" unless [player_one_id, player_two_id].include? player.id
    return "Tied" unless [0, 1].include? result
    win_result = player_one_id == player.id ? 1 : 0
    result == win_result ? "Beat" : "Lost to"
  end
end
