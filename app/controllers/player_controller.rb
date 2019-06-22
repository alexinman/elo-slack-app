class PlayerController < ApplicationController
  def players
    results = PlayerViewModel.list(params)
    render json: results, status: :ok
  end
end
