class Game < ActiveRecord::Base
  belongs_to :player_one, class_name: 'Player'
  belongs_to :player_two, class_name: 'Player'
  belongs_to :game_type

  before_create :set_extra_columns

  scope :for_slack_user_id, ->(slack_user_id) do
    where('player_one_slack_user_id ilike ? or player_two_slack_user_id ilike ?', "%#{slack_user_id}%", "%#{slack_user_id}%")
  end

  def opponent(player)
    player = [player_one, player_two].find { |p| p.slack_user_id.include? player.slack_user_id }
    raise ArgumentError, "player did not play in this game" unless player.present?
    player_one_id == player.id ? player_two : player_one
  end

  def result_for(player)
    player = [player_one, player_two].find { |p| p.slack_user_id.include? player.slack_user_id }
    raise ArgumentError, "player did not play in this game" unless player.present?
    opponent = opponent(player).team_tag
    return "#{player.team_tag} tied #{opponent}" unless [0, 1].include? result
    win_result = player_one_id == player.id ? 1 : 0
    result == win_result ? "#{player.team_tag} beat #{opponent}" : "#{player.team_tag} lost to #{opponent}"
  end

  def result_response
    case result
    when 1
      congratulations(player_one, player_two)
    when 0
      congratulations(player_two, player_one)
    else
      "#{player_one.team_tag} (#{player_one.rating_change}) :#{win_emoji}: tied #{player_two.team_tag} (#{player_two.rating_change}) :#{win_emoji}: at #{game_type.game_name}."
    end
  end

  private

  def set_extra_columns
    self.slack_team_id = player_one.slack_team_id
    self.player_one_slack_user_id = player_one.slack_user_id
    self.player_two_slack_user_id = player_two.slack_user_id
    self.game_type_id = player_one.game_type_id
    self.team_size = player_one.team_size
  end

  def congratulations(winner, loser)
    "Congratulations to #{winner.team_tag} (#{winner.rating_change}) :#{win_emoji}: on defeating #{loser.team_tag} (#{loser.rating_change}) :#{lose_emoji(loser.team_tag)}: at #{game_type.game_name}!"
  end

  def win_emoji
    %w(aaw_yeah awesome awesomesauce awwyeah bananadance carlton cheers clapping congrats dabward dancing_pickle dank datboi deadpool drake excellent fancy fastparrot feelssogood fiestaparrot foleydance gandalf gusta happytony happy_cloud happy_tim heh-heh-heh-hao-owrrrr-rah-heh-heh-heh-heh-huh-huh-haow-hah-haough johncena mat_icon_whatshot nailedit notinmyhouse nyan obama_not_bad parrot party-corgi partywizard party_dino party_frog party_mim_cat party_trash_dove pewpew quag rekt slav_squat spiderman success sunglasses-on-a-baby thanks travis_passed very_nice woohoo yeah yeet yes).sample
  end

  def lose_emoji(team)
    return 'shame' if team.include?('@UBK70UVP1')
    %w(angrytony angry_tim backs-away bruh collins crying disappear disappointed_jacob doh doodie drypenguin dumpster_fire facepalm feelsbad flood garbage grumpycat haha leftshark mooning nooooooo numb okay okthen oof patrickboo puddlearm puke raised_eyebrow sadparrot sadpepe sad_mac sad_rowser santa-derp shame somebodykillme surprised_pikachu swear thisstraycatlookslikegrandma travis_failed triggered unimpressed wellthen why wowen wtf yuno).sample
  end
end
