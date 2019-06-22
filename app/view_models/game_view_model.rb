class GameViewModel < ApplicationViewModel
  class << self
    def list(options = {})
      rel = model_class
                .joins('inner join players player_one on player_one.id = games.player_one_id')
                .joins('inner join players player_two on player_two.id = games.player_two_id')
                .where('player_one.team_id = ?', options[:team_id])
      rel = rel.where('player_one.user_id ilike ? OR player_two.user_id ilike ?', "%#{options[:user_id]}%", "%#{options[:user_id]}%") if options[:user_id].present?
      rel = rel.where('player_one.game_type_id = ?', options[:game_type_id]) if options[:game_type_id].present?
      rel = rel.where('player_one.team_size = ?', options[:team_size]) if options[:team_size].present?
      super(rel, options)
    end

    private

    def model_class
      Game
    end

    def sql_order(options = {})
      case options[:order]
      when 'updated_at'
        model_class.arel_table[:updated_at]
      when 'created_at'
        model_class.arel_table[:created_at]
      else
        model_class.arel_table[:created_at]
      end
    end
  end
end