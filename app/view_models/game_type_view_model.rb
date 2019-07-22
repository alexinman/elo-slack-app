class GameTypeViewModel < ApplicationViewModel
  class << self
    def list(options = {})
      rel = model_class.where(slack_team_id: options[:slack_team_id])
      super(rel, options)
    end

    private

    def model_class
      GameType
    end

    def sql_order(options = {})
      case options[:order].to_s
      when 'game_name'
        model_class.arel_table[:game_name]
      when 'created_at'
        model_class.arel_table[:created_at]
      else
        model_class.arel_table[:created_at]
      end
    end
  end
end