class LeaderboardViewModel < PlayerViewModel
  class << self
    def leaderboard(slack_team_id:, game_type_id:)
      singles = list(slack_team_id: slack_team_id, game_type_id: game_type_id, team_size: 1, direction: :desc).items
      doubles = list(slack_team_id: slack_team_id, game_type_id: game_type_id, team_size: 2, direction: :desc).items

      data = []
      data << attachment(singles.join("\n"), doubles: false) if singles.present?
      data << attachment(doubles.join("\n"), doubles: true) if doubles.present?
      new(data)
    end

    def surrounding_ranks(player)
      players = Player.find_by_sql([<<-SQL, slack_team_id: player.slack_team_id, slack_user_id: player.slack_user_id, game_type_id: player.game_type_id, team_size: player.team_size])
        WITH ranked_players AS (SELECT players.*, DENSE_RANK() OVER (ORDER BY rating DESC) AS rank, RANK() OVER (ORDER BY rating DESC, updated_at ASC) AS pseudo_rank
                                FROM players
                                WHERE players.slack_team_id = :slack_team_id
                                  AND players.game_type_id = :game_type_id
                                  AND players.team_size = :team_size)
        SELECT *
        FROM ranked_players
        WHERE ranked_players.pseudo_rank BETWEEN (SELECT pseudo_rank - 1 FROM ranked_players WHERE slack_user_id = :slack_user_id)
                  AND (SELECT pseudo_rank + 1 FROM ranked_players WHERE slack_user_id = :slack_user_id)
        ORDER BY ranked_players.pseudo_rank;
      SQL
      new(players.map(&method(:item_summary)))
    end

    private

    def attachment(text, doubles:)
      {
          text: text,
          footer_icon: doubles ? doubles_image_url : singles_image_url,
          footer: doubles ? 'Doubles' : 'Singles',
          ts: ts
      }
    end

    def model_class
      Player.select('players.*, dense_rank() over (order by rating desc) as rank')
    end

    def item_summary(player)
      "#{player.rank}. #{player.team_tag} (#{player.rating})"
    end
  end
end