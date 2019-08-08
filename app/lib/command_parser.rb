class CommandParser
  attr_reader :params

  USER_ID_REGEX = '<([^\|>]*)[^>]*>'.freeze
  TEAM_REGEX = "(#{USER_ID_REGEX}(?:[[:space:]]+and[[:space:]]+#{USER_ID_REGEX})*)".freeze
  WIN_TERMS = ['beat', 'defeated', 'conquered', 'won against', 'got the better of', 'vanquished', 'trounced', 'routed',
               'obliterated', 'overpowered', 'overcame', 'overwhelmed', 'overthrew', 'subdued', 'quashed', 'crushed', 
               'thrashed', 'whipped', 'wiped the floor with', 'clobbered', 'owned', 'pwned', 'wrecked'].freeze
  DRAW_TERMS = ['tied', 'drawed'].freeze
  LOSS_TERMS = ['was beat by', 'were beat by', 'was defeated by', 'were defeated by', 'was conquered by',
                'were conquered by', 'lost to', 'lost against', 'was vanquished by', 'were vanquished by',
                'was trounced by', 'were trounced by', 'was routed by', 'were routed by', 'was obliterated by',
                'were obliterated by', 'was overpowered by', 'were overpowered by', 'was overcome by',
                'were overcome by', 'was overwhelmed by', 'were overwhelmed by', 'was overthrown by',
                'were overthrown by', 'was subdued by', 'were subdued by', 'was quashed by', 'were quashed by',
                'was crushed by', 'were crushed by', 'was thrashed by', 'were thrashed by', 'was whipped by',
                'were whipped by', 'was clobbered by', 'were clobbered by', 'was owned by', 'were owned by',
                'was pwned by', 'were pwned by', 'was wrecked by', 'were wrecked by'].freeze
  OTHER_COMMANDS = {
    'rating' => :stats,
    'ranking' => :stats,
    'stats' => :stats,
    'statistics' => :stats,
    'leaderboard' => :leaderboard,
    'register' => :register,
    'games' => :games,
    'help' => :help
  }.freeze
  ALL_ACTIONS = (WIN_TERMS + DRAW_TERMS + LOSS_TERMS + OTHER_COMMANDS.keys).freeze


  def initialize(params)
    @params = params.deep_dup
  end

  def parse
    return @parsed if @parsed.present?
    @parsed = {}
    @parsed[:teams] = parse_teams
    @parsed[:players] = determine_players
    @parsed[:team_size] = determine_team_size
    @parsed[:action] = parse_action
    @parsed[:game_name] = parse_game_name
    @parsed[:game_type] = find_game_type
    @parsed
  end

  def method_missing(method_name, *args, &block)
    return params[method_name] if params.try(:has_key?, method_name)
    super(method_name, *args, &block)
  end

  private

  def parse_teams
    (team1_match, _, _), (team2_match, _, _) = text.scan(/#{TEAM_REGEX}/i)
    return "@#{user_id}", nil unless team1_match.present?
    team1_id = team1_match.scan(/#{USER_ID_REGEX}/).compact.sort.join('-')
    text.sub!(team1_match, '')
    return team1_id, nil unless team2_match.present?
    team2_id = team2_match.scan(/#{USER_ID_REGEX}/).compact.sort.join('-')
    text.sub!(team2_match, '')
    return team1_id, team2_id
  end

  def determine_team_size
    team1_size = @parsed[:teams].first.try(:split, '-').try(:size)
    team2_size = @parsed[:teams].second.try(:split, '-').try(:size)
    if team2_size.nil? || team2_size == team1_size
      team1_size
    else
      :uneven
    end
  end

  def determine_players
    @parsed[:teams].join('-').split('-').uniq
  end

  def parse_action
    regex = /#{ALL_ACTIONS.map { |a| "(#{a.gsub(/[[:space:]]+/, '[[:space:]]+') })" }.join('|')}/i
    action_match = text.match(regex).to_a.first
    return unless action_match.present?
    text.sub!(action_match, '')
    action = action_match.downcase.gsub(/[[:space:]]+/, ' ')
    case action
    when *WIN_TERMS
      :win
    when *DRAW_TERMS
      :draw
    when *LOSS_TERMS
      :loss
    when *OTHER_COMMANDS.keys
      OTHER_COMMANDS[action]
    else
      nil
    end
  end

  def parse_game_name
    text.strip.gsub(/[[:space:]]+/, ' ').downcase.sub(/^at[[:space:]]+/, '').presence || channel_name
  end

  def find_game_type
    return unless @parsed[:game_name].present?
    GameType.where(slack_team_id: team_id, game_name: @parsed[:game_name]).take
  end

  def channel_name
    params[:channel_name] unless params[:channel_name].in? %w(privategroup directmessage)
  end
end