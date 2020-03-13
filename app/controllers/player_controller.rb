class PlayerController < ApplicationController
  def players
    render json: PlayerViewModel.list(params), status: :ok
  end
end
