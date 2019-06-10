class EloController < ApplicationController
  around_filter :error_handling
  before_filter :verify_slack_signature

  VICTORY_TERMS = ['beat', 'defeated', 'conquered', 'won against', 'got the better of', 'vanquished', 'trounced',
                   'routed', 'overpowered', 'overcame', 'overwhelmed', 'overthrew', 'subdued', 'quashed', 'crushed',
                   'thrashed', 'whipped', 'wiped the floor with', 'clobbered', 'owned', 'pwned']
  TIED_TERMS = ['tied', 'drawed']

  def elo
    render json: {message: "missing parameter team_id"}, status: :bad_request if params[:team_id].blank?
    render json: {message: "missing parameter user_id"}, status: :bad_request if params[:user_id].blank?
    return help if params[:text].empty? || params[:text] == "help"
    command, other = params[:text].split
    case command
    when "rating"
      rating
    when "leaderboard"
      leaderboard(other)
    when "register"
      register(other)
    when "games"
      games
    else
      game
    end
  end

  private

  def verify_slack_signature
    version_number = 'v0' # always v0 for now
    timestamp = request.headers['X-Slack-Request-Timestamp']
    raw_body = request.body.read
    sig_basestring = [version_number, timestamp, raw_body].join(':')

    signing_secret = ENV['SLACK_SIGNING_SECRET'].to_s
    digest = OpenSSL::Digest::SHA256.new
    hex_hash = OpenSSL::HMAC.hexdigest(digest, signing_secret, sig_basestring)
    computed_signature = [version_number, hex_hash].join('=')
    slack_signature = request.headers['X-Slack-Signature']

    render nothing: true, status: :unauthorized if computed_signature != slack_signature
  end

  def error_handling
    yield
  rescue => e
    Rails.logger.error "#{e.message}\n#{e.backtrace.first(5).join("\n")}"
    reply "Uh oh! Something went wrong. Please contact Alex. :dusty_stick:"
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

  def leaderboard(args)
    type = Array.wrap(args).join(" ")
    return help unless type.present?

    game_type = find_game_type(type)
    return unless game_type

    players = Player.where(team_id: current_team, game_type_id: game_type.id).order(rating: :desc).take(10)
    text = if players.empty?
             "No one has played any ELO rated games of #{type} yet."
           else
             players.each_with_index.map { |player, index| "#{index + 1}. <#{player.user_id}> (#{player.rating})" }.join("\n")
           end
    reply text
  end

  def rating
    players = Player.where(team_id: current_team, user_id: current_user).includes(:game_type).to_a
    text = if players.empty?
             "You haven't played any ELO rated games yet."
           else
             players.map { |player| "Your rating in #{player.game_type.game_type} is #{player.rating}." }.join("\n")
           end
    reply text
  end

  def register(args)
    type = Array.wrap(args).join(" ")
    return help unless type.present?

    game_type = GameType.where(team_id: current_team, game_type: type).take
    reply "That game has already been registered." if game_type.present?

    game_type = GameType.create!(team_id: current_team, game_type: type)
    reply "Successfully registered #{game_type.game_type} for this team!"
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
    _, p1, verb, p2, type = params[:text].match(/^<([^\|]*).*> ([a-z ]*) <([^\|]*).*> at ([a-z ]*)\.?$/).to_a
    return help if p1.blank? || p2.blank? || type.blank?

    reply "A third-party witness must enter the game for it to count." and return if [p1, p2].include? current_user
    reply ":areyoukiddingme:" and return if ([p1, p2] & %w(@USLACKBOT !channel !here)).present?
    reply "<#{p1}> can't even beat themself at #{type} :#{lose_emoji}:" and return if p1 == p2

    game_type = find_game_type(type)
    return unless game_type

    p1 = Player.where(team_id: current_team, user_id: p1, game_type_id: game_type.id).first_or_initialize
    p2 = Player.where(team_id: current_team, user_id: p2, game_type_id: game_type.id).first_or_initialize

    case verb
    when *VICTORY_TERMS
      p1.won_against p2, current_user
      reply "Congratulations to <#{p1.user_id}> :#{win_emoji}: on defeating <#{p2.user_id}> :#{lose_emoji}: at #{type}!", in_channel: true
    when *TIED_TERMS
      p1.tied_with p2, current_user
      reply "<#{p1.user_id}> :#{win_emoji}: tied <#{p2.user_id}> :#{win_emoji}: at #{type}.", in_channel: true
    else
      return help
    end
  end

  def find_game_type(type)
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
  end

  def reply(text, in_channel: false, attachments: [])
    response = {
        response_type: in_channel ? "in_channel" : "ephemeral",
        text: text,
        attachments: attachments
    }
    render json: response, status: :ok and return nil
  end

  def win_emoji
    %w(aaw_yeah awesome awesomesauce awwyeah bananadance carlton cheers clapping congrats dabward dancing_pickle dank datboi deadpool drake excellent fancy fastparrot feelssogood fiestaparrot foleydance gandalf gusta happytony happy_cloud happy_tim heh-heh-heh-hao-owrrrr-rah-heh-heh-heh-heh-huh-huh-haow-hah-haough johncena mat_icon_whatshot nailedit notinmyhouse nyan obama_not_bad parrot party-corgi partywizard party_dino party_frog party_mim_cat party_trash_dove pewpew quag rekt slav_squat spiderman success sunglasses-on-a-baby thanks travis_passed very_nice woohoo yeah yeet yes).sample
  end

  def lose_emoji
    %w(angrytony angry_tim backs-away bruh collins crying disappear disappointed_jacob doh doodie drypenguin dumpster_fire facepalm feelsbad flood garbage grumpycat haha leftshark mooning nooooooo numb okay okthen oof patrickboo puddlearm puke raised_eyebrow sadparrot sadpepe sad_mac sad_rowser santa-derp shame somebodykillme surprised_pikachu swear thisstraycatlookslikegrandma travis_failed triggered unimpressed wellthen why wowen wtf yuno).sample
  end

  def current_team
    params[:team_id]
  end

  def current_user
    "@#{params[:user_id]}"
  end
end