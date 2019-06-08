class EloController < ApplicationController
  around_filter :error_handling

  def elo
    render json: {message: "missing parameter team_id"}, status: :bad_request if params[:team_id].blank?
    render json: {message: "missing parameter user_id"}, status: :bad_request if params[:user_id].blank?
    return help if params[:text].empty? || params[:text] == "help"
    command, other = params[:text].split
    case command
    when "rating"
      rating(other)
    else
      game
    end
  end

  private

  def error_handling
    yield
  rescue => e
    puts "#{e.message}\n#{e.backtrace.join("\n")}"
    render json: {
        response_type: "ephemeral",
        text: "Uh oh! Something went wrong. Please try again."
    }, status: :ok
  end

  def help
    response = {
        response_type: "ephemeral",
        text: ":wave: Need some help with `/elo`? Ask Alex."
    }
    render json: response, status: :ok
  end

  def rating(args)
    players = Player.where(team_id: params[:team_id], user_id: params[:user_id]).to_a
    text = if players.empty?
             "You haven't played any ELO rated games yet."
           else
             players.map { |player| "Your rating in #{player.game_type} is #{player.rating}." }.join("\n")
           end
    response = {
        response_type: "ephemeral",
        text: text
    }
    render json: response, status: :ok
  end

  def game
    _, p1, p2, game_type = params[:text].match(/^<([^\|]*).*> beat <([^\|]*).*> at ([a-z]*)$/).to_a
    return help if p1.blank? || p2.blank? || game_type.blank?

    p1 = Player.where(team_id: params[:team_id], user_id: p1, game_type: game_type).first_or_initialize
    p2 = Player.where(team_id: params[:team_id], user_id: p2, game_type: game_type).first_or_initialize
    p1.beats p2, params[:user_id]

    response = {
        response_type: "in_channel",
        text: "Congratulations to <#{p1.user_id}> on beating <#{p2.user_id}> at #{game_type}."
    }
    render json: response, status: :ok
  end
end