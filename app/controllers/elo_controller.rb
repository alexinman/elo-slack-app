class EloController < CommandParser
  before_filter :verify_slack_signature
  before_filter :parse_commands

  def elo
    self.send(command.to_s.downcase) if @response.blank?
    reply "Hey, something went wrong. If you see this message, please message Alain or drop a message in #elo-dev. Thanks!" if @response.blank?
    render json: @response, status: :ok
  end

  private

  def leaderboard
    game_type = find_game_type
    return unless game_type

    results = LeaderboardViewModel.leaderboard(team_id: current_team, game_type_id: game_type.id).items
    reply "No one has played any ELO rated games of #{game_type.game_type} yet." and return if results.empty?
    reply "Here is the current leaderboard for #{game_type.game_type}:", attachments: results
  end

  def stats
    player = @parsed_command[:p1] || current_user
    type = @parsed_command[:type]
    results = PlayerViewModel.statistics(team_id: current_team, user_id: player, game_type: type).items
    reply "#{player == current_user ? "You haven't" : "<#{player}> hasn't"} played any ELO rated games #{type.present? ? "of #{type} " : ""}yet." and return if results.empty?
    reply attachments: results
  end

  def victory
    team1 = find_teams[:team1]
    team2 = find_teams[:team2]
    team1.won_against team2, current_user
    reply "Congratulations to #{team1.team_tag} (#{team1.rating_change}) :#{win_emoji}: on defeating #{team2.team_tag} (#{team2.rating_change}) :#{lose_emoji(team2.team_tag)}: at #{find_game_type.game_type}!", in_channel: true
  end

  def tied
    team1 = find_teams[:team1]
    team2 = find_teams[:team2]
    team1.tied_with team2, current_user
    reply "#{team1.team_tag} (#{team1.rating_change}) :#{win_emoji}: tied #{team2.team_tag} (#{team2.rating_change}) :#{win_emoji}: at #{find_game_type.game_type}.", in_channel: true
  end

  def win_emoji
    %w(aaw_yeah awesome awesomesauce awwyeah bananadance carlton cheers clapping congrats dabward dancing_pickle dank datboi deadpool drake excellent fancy fastparrot feelssogood fiestaparrot foleydance gandalf gusta happytony happy_cloud happy_tim heh-heh-heh-hao-owrrrr-rah-heh-heh-heh-heh-huh-huh-haow-hah-haough johncena mat_icon_whatshot nailedit notinmyhouse nyan obama_not_bad parrot party-corgi partywizard party_dino party_frog party_mim_cat party_trash_dove pewpew quag rekt slav_squat spiderman success sunglasses-on-a-baby thanks travis_passed very_nice woohoo yeah yeet yes).sample
  end

  def lose_emoji(team)
    return 'shame' if team.include?('@UBK70UVP1')
    %w(angrytony angry_tim backs-away bruh collins crying disappear disappointed_jacob doh doodie drypenguin dumpster_fire facepalm feelsbad flood garbage grumpycat haha leftshark mooning nooooooo numb okay okthen oof patrickboo puddlearm puke raised_eyebrow sadparrot sadpepe sad_mac sad_rowser santa-derp shame somebodykillme surprised_pikachu swear thisstraycatlookslikegrandma travis_failed triggered unimpressed wellthen why wowen wtf yuno).sample
  end
end