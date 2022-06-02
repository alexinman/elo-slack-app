class EloController < ApplicationController
  before_filter :verify_slack_signature

  def elo
    render json: {message: "missing parameter team_id"}, status: :bad_request and return if params[:team_id].blank?
    render json: {message: "missing parameter user_id"}, status: :bad_request and return if params[:user_id].blank?
    render json: {message: "missing parameter text"}, status: :bad_request and return if params[:text].nil?
    @parsed = CommandParser.new(params).parse
    @parsed[:action].present? ? send(@parsed[:action]) : help
    render json: @response, status: :ok
  end

  private

  def help
    attachments = [
        {
            text:
                "`/elo [@winner] defeated [@loser] at [game]` - Logs a game between these players and updates their ratings accordingly.\n" <<
                    "`/elo [@player1] tied [@player2] at [game]` - Logs a tie game between these players and updates their ratings accordingly.\n" <<
                    "`/elo leaderboard [game]` - Displays the leaderboard for the specified game.\n" <<
                    "`/elo rating [@player] [game]` - Displays your Elo rating for all types of games you've played. (Optional parameters allow you to filter to a specific game or view someone else's stats.)\n" <<
                    "`/elo games` - Lists all registered games for this team. (a.k.a. Valid inputs for [game] in other commands).\n" <<
                    "`/elo register [game]` - Registers this as a type of game that this team plays.\n"
        }
    ]
    reply ":wave: Need some help with `/elo`? Here are some useful commands:", attachments: attachments
  end

  def invalid_game_name
    reply "Sorry! :sweat_smile: We couldn't determine what game you're referring to. Please make sure the game you're referring to is registered (`/elo games`) and if it isn't, please register it (`/elo register [game]`)."
  end

  def leaderboard
    return invalid_game_name unless @parsed[:game_type].present?
    results = LeaderboardViewModel.leaderboard(slack_team_id: current_team, game_type_id: @parsed[:game_type].id).items
    reply "No one has played any ELO rated games of #{@parsed[:game_name]} yet." and return if results.empty?
    reply "Here is the current leaderboard for #{@parsed[:game_name]}:", attachments: results
  end

  def stats
    results = PlayerViewModel.statistics(slack_team_id: current_team, slack_user_id: @parsed[:teams].first, game_type_id: @parsed[:game_type].try(:id)).items
    reply attachments: results and return unless results.empty?

    tag = @parsed[:teams].first.split('-').map { |id| id == current_user ? 'You' : "<#{id}>" }.sort.reverse.to_sentence
    verb_conjugation = tag.include?('You') || tag.include?('and') ? "haven't" : "hasn't"
    reply "#{tag} #{verb_conjugation} played any ELO rated games #{@parsed[:game_type].present? ? "of #{@parsed[:game_type].game_name} " : ""}yet."
  end

  def register
    reply "You must provide the name of the game you'd like to register. (Private Groups and Direct Messages cannot be used as game names.)" and return unless @parsed[:game_name].present?
    reply "That game has already been registered." and return if @parsed[:game_type].present?
    game_type = GameType.create!(slack_team_id: current_team, game_name: @parsed[:game_name])
    reply "Successfully registered #{game_type.game_name} as a game for this team!"
  end

  def games
    game_names = GameType.where(slack_team_id: current_team).pluck(:game_name)
    text = if game_names.empty?
             "No types of games have been registered for this team yet. Try `/elo register [game]`."
           else
             "Here are all the registered types of games for this team:\n#{game_names.map { |name| "• #{name}" }.join("\n")}"
           end
    reply text
  end

  def win
    game(1)
  end

  def loss
    game(0)
  end

  def draw
    game(0.5)
  end

  def game(result)
    reply "2 on 1 isn't very fair :dusty_stick:" and return if @parsed[:team_size] == :uneven
    # reply "A third-party witness must enter the game for it to count." and return if @parsed[:players].include? current_user
    reply ":areyoukiddingme:" and return if (@parsed[:players] & %w(@USLACKBOT !channel !here)).present?
    reply "Am I seeing double or did you enter the same person multiple times? :twinsparrot:" and return if @parsed[:players].size != @parsed[:team_size] * 2
    return invalid_game_name unless @parsed[:game_type].present?

    team1 = Player.where(slack_team_id: current_team, slack_user_id: @parsed[:teams].first, game_type_id: @parsed[:game_type].id, team_size: @parsed[:team_size]).first_or_initialize
    team2 = Player.where(slack_team_id: current_team, slack_user_id: @parsed[:teams].second, game_type_id: @parsed[:game_type].id, team_size: @parsed[:team_size]).first_or_initialize
    game = team1.log_game(team2, current_user, result)
    reply game.result_response, in_channel: true
  end
end