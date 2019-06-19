class GameController < ApplicationController

  #history of all games
  def history
    per_page = params[:per_page].try(:to_i) || 10
    page = params[:page].try(:to_i) || 1
    games = Game.order(created_at: :desc, id: :desc).paginate(page: page, per_page: per_page)
    render json: games, status: :ok
  end

  #get list of games
  def gametypes
    render json: GameType.all, status: :ok
  end
end
