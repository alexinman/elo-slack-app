class CommandParser < ApplicationController
  ELO_COMMANDS = {
      :VICTORY_TERMS => ['beat', 'defeated', 'conquered', 'won against', 'got the better of', 'vanquished', 'trounced',
                         'routed', 'obliterated', 'overpowered', 'overcame', 'overwhelmed', 'overthrew', 'subdued', 'quashed',
                         'crushed', 'thrashed', 'whipped', 'wiped the floor with', 'clobbered', 'owned', 'pwned', 'wrecked'],
      :TIED_TERMS => %w(tied drawed),
      :CHALLENGE_TERMS => %w(challenge challenges challenged summon summons invite invites invited)
  }

  UNARY_COMMANDS = {
      :REGISTER_TERMS => %w(register),
      :HELP_TERMS => %w(help),
      :GAMES_TERMS => %w(games list),
      :LEADERBOARD_TERMS => %w(leaderboard best top),
      :STATS_TERMS => %w(rating ranking stats)
  }

  def parse_commands
    @parsed_command = {}
    _, @parsed_command[:p1],
        @parsed_command[:p2],
        @parsed_command[:verb],
        @parsed_command[:p3],
        @parsed_command[:p4],
        @parsed_command[:type] =
        params[:text].match(/^#{SLACK_ID_REGEX}(?: +and +#{SLACK_ID_REGEX})? +([a-zA-Z ]*) +#{SLACK_ID_REGEX}(?: +and +#{SLACK_ID_REGEX})?(?: +at +(.*))?$/).to_a

    case command
    when :HELP
      help
    when :REGISTER
      register
    end

    @parsed_command
  end

  private

  def parse_unary_commands
    word = params[:text].split[0].downcase
    (UNARY_COMMANDS.map { |k, v| k.to_s.gsub(/_TERMS/, '').to_sym if v.include?word })
  end

  def parse_elo_commands
    verb = "#{@parsed_command[:verb].presence}".strip.downcase
    (ELO_COMMANDS.map { |k, v| k.to_s.gsub(/_TERMS/, '').to_sym if v.include?verb })
  end

  def command
    @parsed_command[:command] if @parsed_command.present?

    command = (parse_unary_commands << parse_elo_commands).flatten.compact
    help and return nil if command.size != 1
    @parsed_command[:command] = command.first
  end

  def register
    words = params[:text].split
    help and return nil if words.size > 2

    type = words.size == 2 ? words[1].downcase : params[:channel_name]

    game_type = GameType.where(team_id: current_team, game_type: type).take
    reply "That game has already been registered." and return if game_type.present?

    game_type = GameType.create!(team_id: current_team, game_type: type)
    reply "Successfully registered #{game_type.game_type} as a game for this team!"
  end

  def help
    attachments = [
        {
            text:
                "`/elo [@winner] defeated [@loser] at [game]` - Logs a game between these players and updates their ratings accordingly.\n" <<
                    "`/elo [@player1] tied [@player2] at [game]` - Logs a tie game between these players and updates their ratings accordingly.\n" <<
                    "`/elo leaderboard [game]` - Displays the leaderboard for the specified game.\n" <<
                    "`/elo rating` - Displays your Elo rating for all types of games you've played.\n" <<
                    "`/elo games` - Lists all registered games for this team. (a.k.a. Valid inputs for [game] in other commands).\n" <<
                    "`/elo register [game]` - Registers this as a type of game that this team plays.\n" <<
                    "`/elo help` - Shows this message."
        }
    ]
    reply ":wave: Need some help with `/elo`? Here are some useful commands:", attachments: attachments
  end

  def find_game_type
    @parsed_command[:parsed_type] if @parsed_command[:parsed_type].present?

    type = @parsed_command[:type].presence || params[:channel_name]
    game_type = GameType.where(team_id: current_team, game_type: type).take
    @parsed_command[:parsed_type] = game_type and return game_type unless game_type.nil?
    attachments = [
        {
            text:
                "`/elo games` - Lists all registered games for this team. (a.k.a. Valid inputs for [game] in other commands).\n" <<
                    "`/elo register [game]` - Registers this as a type of game that this team plays."
        }
    ]
    reply "The game of #{type} has not be registered for this team yet. Try using one of the following commands to find or register the game you're looking for.", attachments: attachments
  end

  def find_teams
    @parsed_command[:teams] if @parsed_command[:teams].present?

    p1, p2, p3, p4 = get_players
    help and return nil if p1.blank? || p3.blank?
    reply "2 on 1 isn't very fair :dusty_stick:" and return if [p2, p4].compact.count == 1
    reply "A third-party witness must enter the game for it to count." and return if [p1, p2, p3, p4].include? current_user
    reply ":areyoukiddingme:" and return if ([p1, p2, p3, p4].compact & %w(@USLACKBOT !channel !here)).present?
    team_size = p2.present? && p4.present? ? 2 : 1
    reply "Am I seeing double or did you enter the same person multiple times? :twinsparrot:" and return if [p1, p2, p3, p4].compact.uniq.count != team_size * 2

    team1 = Player.where(team_id: current_team, user_id: [p1, p2].compact.sort.join('-'), game_type_id: find_game_type.id, team_size: team_size).first_or_initialize
    team2 = Player.where(team_id: current_team, user_id: [p3, p4].compact.sort.join('-'), game_type_id: find_game_type.id, team_size: team_size).first_or_initialize

    @parsed_command[:teams] = { :team1 => team1, :team2 => team2 }
  end

  def games
    game_types = GameType.where(team_id: current_team).to_a
    text = if game_types.empty?
             "No types of games have been registered for this team yet. Try `/elo register [game]`."
           else
             "Here are all the registered types of games for this team:\n#{game_types.map { |game_type| "• #{game_type.game_type}" }.join("\n")}"
           end
    reply text
  end

  def get_players
    [
        @parsed_command[:p1],
        @parsed_command[:p2],
        @parsed_command[:p3],
        @parsed_command[:p4]
    ]
  end
end
