class EloController < ApplicationController
  before_filter :verify_slack_signature

  VICTORY_TERMS = ['beat', 'defeated', 'conquered', 'won against', 'got the better of', 'vanquished', 'trounced',
                   'routed', 'obliterated', 'overpowered', 'overcame', 'overwhelmed', 'overthrew', 'subdued', 'quashed',
                   'crushed', 'thrashed', 'whipped', 'wiped the floor with', 'clobbered', 'owned', 'pwned', 'wrecked']
  TIED_TERMS = ['tied', 'drawed']

  def elo
    render json: {message: "missing parameter user_id"}, status: :bad_request if params[:user_id].blank?
    command, _, other = params[:text].partition(" ")
    case command
    when "rating", "ranking", "stats"
      stats(other)
    when "leaderboard"
      leaderboard(other)
    when "register"
      register(other)
    when "games"
      games
    when "help"
      help
    else
      game
    end
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
                    "`/elo rating` - Displays your Elo rating for all types of games you've played.\n" <<
                    "`/elo games` - Lists all registered games for this team. (a.k.a. Valid inputs for [game] in other commands).\n" <<
                    "`/elo register [game]` - Registers this as a type of game that this team plays.\n" <<
                    "`/elo help` - Shows this message."
        }
    ]
    reply ":wave: Need some help with `/elo`? Here are some useful commands:", attachments: attachments
  end

  def leaderboard(type)
    game_type = find_game_type(type)
    return unless game_type

    results = LeaderboardViewModel.leaderboard(team_id: current_team, game_type_id: game_type.id).items
    reply "No one has played any ELO rated games of #{game_type.game_type} yet." and return if results.empty?
    reply "Here is the current leaderboard for #{game_type.game_type}:", attachments: results
  end

  def stats(args)
    _, user_id = args.match(/#{SLACK_ID_REGEX}/).to_a
    type = args.gsub(/#{SLACK_ID_REGEX}/, '').strip
    user_id ||= current_user
    results = PlayerViewModel.statistics(team_id: current_team, user_id: user_id, game_type: type).items
    reply "#{user_id == current_user ? "You haven't" : "<#{user_id}> hasn't"} played any ELO rated games #{type.present? ? "of #{type} " : ""}yet." and return if results.empty?
    reply attachments: results
  end

  def register(type)
    type = type.presence || params[:channel_name]

    game_type = GameType.where(team_id: current_team, game_type: type).take
    reply "That game has already been registered." and return if game_type.present?

    game_type = GameType.create!(team_id: current_team, game_type: type)
    reply "Successfully registered #{game_type.game_type} as a game for this team!"
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

  def game
    _, p1, p2, verb, p3, p4, type = params[:text].match(/^#{SLACK_ID_REGEX}(?: +and +#{SLACK_ID_REGEX})? +([a-zA-Z ]*) +#{SLACK_ID_REGEX}(?: +and +#{SLACK_ID_REGEX})?(?: +at +(.*))?$/).to_a
    return help if p1.blank? || p3.blank?

    reply "2 on 1 isn't very fair :dusty_stick:" and return if [p2, p4].compact.count == 1
    reply "A third-party witness must enter the game for it to count." and return if [p1, p2, p3, p4].include? current_user
    reply ":areyoukiddingme:" and return if ([p1, p2, p3, p4].compact & %w(@USLACKBOT !channel !here)).present?
    team_size = p2.present? && p4.present? ? 2 : 1
    reply "Am I seeing double or did you enter the same person multiple times? :twinsparrot:" and return if [p1, p2, p3, p4].compact.uniq.count != team_size * 2

    game_type = find_game_type(type)
    return unless game_type

    team1 = Player.where(team_id: current_team, user_id: [p1, p2].compact.sort.join('-'), game_type_id: game_type.id, team_size: team_size).first_or_initialize
    team2 = Player.where(team_id: current_team, user_id: [p3, p4].compact.sort.join('-'), game_type_id: game_type.id, team_size: team_size).first_or_initialize

    case verb.strip.downcase
    when *VICTORY_TERMS
      team1.won_against team2, current_user
      reply "Congratulations to #{team1.team_tag} (#{team1.rating_change}) :#{win_emoji}: on defeating #{team2.team_tag} (#{team2.rating_change}) :#{lose_emoji(team2.team_tag)}: at #{game_type.game_type}!", in_channel: true
    when *TIED_TERMS
      team1.tied_with team2, current_user
      reply "#{team1.team_tag} (#{team1.rating_change}) :#{win_emoji}: tied #{team2.team_tag} (#{team2.rating_change}) :#{win_emoji}: at #{game_type.game_type}.", in_channel: true
    else
      return help
    end
  end

  def find_game_type(type)
    type = type.presence || params[:channel_name]
    game_type = GameType.where(team_id: current_team, game_type: type).take
    return game_type unless game_type.nil?
    attachments = [
        {
            text:
                "`/elo games` - Lists all registered games for this team. (a.k.a. Valid inputs for [game] in other commands).\n" <<
                    "`/elo register [game]` - Registers this as a type of game that this team plays."
        }
    ]
    reply "The game of #{type} has not be registered for this team yet. Try using one of the following commands to find or register the game you're looking for.", attachments: attachments
    return nil
  end

  def win_emoji
    %w(aaw_yeah awesome awesomesauce awwyeah bananadance carlton cheers clapping congrats dabward dancing_pickle dank datboi deadpool drake excellent fancy fastparrot feelssogood fiestaparrot foleydance gandalf gusta happytony happy_cloud happy_tim heh-heh-heh-hao-owrrrr-rah-heh-heh-heh-heh-huh-huh-haow-hah-haough johncena mat_icon_whatshot nailedit notinmyhouse nyan obama_not_bad parrot party-corgi partywizard party_dino party_frog party_mim_cat party_trash_dove pewpew quag rekt slav_squat spiderman success sunglasses-on-a-baby thanks travis_passed very_nice woohoo yeah yeet yes).sample
  end

  def lose_emoji(team)
    return 'shame' if team.include?('@UBK70UVP1')
    %w(angrytony angry_tim backs-away bruh collins crying disappear disappointed_jacob doh doodie drypenguin dumpster_fire facepalm feelsbad flood garbage grumpycat haha leftshark mooning nooooooo numb okay okthen oof patrickboo puddlearm puke raised_eyebrow sadparrot sadpepe sad_mac sad_rowser santa-derp shame somebodykillme surprised_pikachu swear thisstraycatlookslikegrandma travis_failed triggered unimpressed wellthen why wowen wtf yuno).sample
  end
end