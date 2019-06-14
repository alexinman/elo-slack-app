class WebapiController < ApplicationController
  include ActionView::Helpers::AssetUrlHelper

  #history of all games
  def history
    games = Player.order(updated_at: :asc)
    render json: games, status: :ok
  end

  #history of 1 game
  def leaderboard
    type = params[:name]
    if type == nil
      return render json: {error: "game name required"}, status: 404
    end
    game_type = GameType.where(game_type: type).take
    if game_type == nil
      return render json: {error: "game not found"}, status: 404
    end
    games = Player.where(game_type_id: game_type).order(rating: :desc)
    
    render json: games, status: :ok
  end

  #get list of games
  def gametypes
    render json: GameType.all, status: :ok
  end
end
