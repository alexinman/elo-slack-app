class PlayerViewModel < ApplicationViewModel
  class << self
    def list(options = {})
      rel = model_class.where(team_id: options[:team_id])
      rel = rel.for_user_id(options[:user_id]) if options[:user_id].present?
      rel = rel.where(game_type_id: options[:game_type_id]) if options[:game_type_id].present?
      rel = rel.where(team_size: options[:team_size]) if options[:team_size].present?
      super(rel, options)
    end

    def statistics(options = {})
      rel = model_class.where(team_id: options[:team_id])
                .for_user_id(options[:user_id])
                .includes(:game_type)
      rel = rel.where(game_types: {game_type: options[:game_type]}) if options[:game_type].present?
      rel = rel.where(team_size: options[:team_size]) if options[:team_size].present?
      data = paginate(rel, per_page: 20, &method(:statistics_summary))
      new(data)
    end

    private

    def statistics_summary(player)
      {
          title: player.team_tag,
          fallback: "Elo rating: #{player.rating}",
          fields: fields(player),
          footer: player.game_type.titleize,
          footer_icon: player.doubles? ? doubles_image_url : singles_image_url,
          ts: ts
      }
    end

    def fields(player)
      fields = []
      fields << field('Rank', LeaderboardViewModel.surrounding_ranks(player).items.join("\n"))
      fields << field('Wins', player.number_of_wins, short: true)
      fields << field('Losses', player.number_of_losses, short: true)
      fields << field('Ties', player.number_of_ties, short: true) if player.number_of_ties > 0
      fields << field('Nemesis', player.nemesis) if player.nemesis.present?
      fields << field('Recent Games', GameViewModel.recent_games(player).items.join("\n"))
      fields
    end

    def field(title, value, short: false)
      {
          title: title,
          value: value,
          short: short
      }
    end

    def model_class
      Player
    end

    def sql_order(options = {})
      case options[:order].to_s
      when 'team_size'
        model_class.arel_table[:team_size]
      when 'updated_at'
        model_class.arel_table[:updated_at]
      when 'created_at'
        model_class.arel_table[:created_at]
      when 'rating'
        model_class.arel_table[:rating]
      else
        model_class.arel_table[:rating]
      end
    end
  end
end