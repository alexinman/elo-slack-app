class EloController < ApplicationController
  around_filter :error_handling

  VICTORY_TERMS = ['beat', 'defeated', 'conquered', 'won against', 'got the better of', 'vanquished', 'trounced',
                   'routed', 'overpowered', 'overcame', 'overwhelmed', 'overthrew', 'subdued', 'quashed', 'crushed',
                   'thrashed', 'whipped', 'wiped the floor with', 'clobbered', 'owned', 'pwned']

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
    else
      game
    end
  end

  private

  def error_handling
    yield
  rescue => e
    puts "#{e.message}\n#{e.backtrace.join("\n")}"
    reply "Uh oh! Something went wrong. Please contact Alex. :dusty_stick:"
  end

  def help
    reply ":wave: Need some help with `/elo`? Ask Alex."
  end

  def leaderboard(args)
    game_type, _ = args
    return help unless game_type.present?

    players = Player.where(team_id: current_team, game_type: game_type).order(rating: :desc).take(10)
    text = if players.empty?
             "No one has played any ELO rated games of #{game_type} yet."
           else
             players.each_with_index.map { |player, index| "#{index + 1}. <#{player.user_id}> (#{player.rating})" }.join("\n")
           end
    reply text
  end

  def rating
    players = Player.where(team_id: current_team, user_id: current_user).to_a
    text = if players.empty?
             "You haven't played any ELO rated games yet."
           else
             players.map { |player| "Your rating in #{player.game_type} is #{player.rating}." }.join("\n")
           end
    reply text
  end

  def game
    _, p1, verb, p2, game_type = params[:text].match(/^<([^\|]*).*> ([a-z ]*) <([^\|]*).*> at ([a-z]*)\.?$/).to_a
    return help if p1.blank? || p2.blank? || game_type.blank? || VICTORY_TERMS.exclude?(verb)

    reply "A third-party witness must enter the game for it to count." and return if [p1, p2].include? current_user
    reply ":areyoukiddingme:" and return if ([p1, p2] & %w(@USLACKBOT !channel !here)).present?
    reply "<#{p1}> can't even beat themself at #{game_type} :okay:" and return if p1 == p2

    p1 = Player.where(team_id: current_team, user_id: p1, game_type: game_type).first_or_initialize
    p2 = Player.where(team_id: current_team, user_id: p2, game_type: game_type).first_or_initialize
    p1.beats p2, current_user

    reply "Congratulations to <#{p1.user_id}> :#{win_emoji}: on beating <#{p2.user_id}> :#{lose_emoji}: at #{game_type}!", "in_channel"
  end

  def reply(text, response_type = "ephemeral")
    response = {
        response_type: response_type,
        text: text
    }
    render json: response, status: :ok
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