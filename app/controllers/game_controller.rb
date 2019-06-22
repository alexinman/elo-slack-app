class GameController < ApplicationController
  def games
    results = GameViewModel.list(params)
    render json: results, status: :ok
  end

  def types
    results = GameTypeViewModel.list(params)
    render json: results, status: :ok
  end
end
