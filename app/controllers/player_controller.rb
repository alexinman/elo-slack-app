class PlayerController < ApplicationController
  #history of 1 game
  def leaderboard
    type = params[:type]
    team_size = params[:team_size]
    return render json: {error: "game name required"}, status: :bas_request if type == nil
    game_type = GameType.where(game_type: type).take
    return render json: {error: "game not found"}, status: :bad_request if game_type == nil
    players = Player.where(game_type_id: game_type).order(rating: :desc)
    players = players.where(team_size: team_size) if team_size != nil
    render json: players, status: :ok
  end
end
