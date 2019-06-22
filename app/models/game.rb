class Game < ActiveRecord::Base
  belongs_to :player_one, class_name: 'Player'
  belongs_to :player_two, class_name: 'Player'

  before_create :set_extra_columns

  def opponent(player)
    raise ArgumentError, "player did not play in this game" unless [player_one_id, player_two_id].include? player.id
    player_one_id == player.id ? player_two : player_one
  end

  def result_for(player)
    raise ArgumentError, "player did not play in this game" unless [player_one_id, player_two_id].include? player.id
    opponent = opponent(player).team_tag
    return "Tied #{opponent}" unless [0, 1].include? result
    win_result = player_one_id == player.id ? 1 : 0
    result == win_result ? "Beat #{opponent}" : "Lost to #{opponent}"
  end

  private

  def set_extra_columns
    self.team_id = player_one.team_id
    self.player_one_user_id = player_one.user_id
    self.player_two_user_id = player_two.user_id
    self.game_type_id = player_one.game_type_id
    self.team_size = player_one.team_size
  end
end
