class GameViewModel < ApplicationViewModel
  class << self
    def list(options = {})
      rel = model_class.where(slack_team_id: options[:slack_team_id])
      rel = rel.for_slack_user_id(options[:slack_user_id]) if options[:slack_user_id].present?
      rel = rel.where(game_type_id: options[:game_type_id]) if options[:game_type_id].present?
      rel = rel.where(team_size: options[:team_size]) if options[:team_size].present?
      super(rel, options)
    end

    def recent_games(player)
      rel = player.games.includes(:player_one, :player_two)
      rel = sort(rel, order: :created_at, direction: :desc)
      data = paginate(rel, per_page: 5) { |game| "• #{game.created_at.slack_format}: #{game.result_for(player)}" }
      new(data)
    end

    private

    def model_class
      Game
    end

    def sql_order(options = {})
      case options[:order].to_s
      when 'updated_at'
        model_class.arel_table[:updated_at]
      else
        model_class.arel_table[:created_at]
      end
    end
  end
end