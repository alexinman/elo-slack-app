class GameController < ApplicationController
  def games
    render json: GameViewModel.list(params), status: :ok
  end

  def types
    render json: GameTypeViewModel.list(params), status: :ok
  end
end
