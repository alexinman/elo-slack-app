class GameViewModel < ApplicationViewModel
  class << self
    def list(options = {})
      rel = model_class.where(team_id: options[:team_id])
      rel = rel.where('user_id ilike ?', "%#{options[:user_id]}%") if options[:user_id].present?
      rel = rel.where(game_type_id: options[:game_type_id]) if options[:game_type_id].present?
      rel = rel.where(team_size: options[:team_size]) if options[:team_size].present?
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