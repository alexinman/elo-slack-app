class PlayerController < ApplicationController
  #history of 1 game
  def leaderboard
    type = params[:type]
    team_size = params[:team_size]
    per_page = params[:per_page].try(:to_i) || 10
    page = params[:page].try(:to_i) || 1
    return render json: {error: "game type required"}, status: :bad_request if type.nil?
    game_type = GameType.where(game_type: type).take
    return render json: {error: "game not found"}, status: :bad_request if game_type.nil?
    players = Player.where(game_type_id: game_type).order(rating: :desc, id: :desc)
    players = players.where(team_size: team_size).paginate(page: page, per_page: per_page)
    render json: players, status: :ok
  end
end
