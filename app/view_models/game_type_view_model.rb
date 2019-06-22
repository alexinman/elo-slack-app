class GameTypeViewModel < ApplicationViewModel
  class << self
    def list(options = {})
      rel = model_class.where(team_id: options[:team_id])
      super(rel, options)
    end

    private

    def model_class
      GameType
    end

    def sql_order(options = {})
      case options[:order]
      when 'game_type'
        model_class.arel_table[:game_type]
      when 'created_at'
        model_class.arel_table[:created_at]
      else
        model_class.arel_table[:created_at]
      end
    end
  end
end