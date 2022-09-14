FactoryBot.define do
  factory :game_type do
    sequence(:game_name) { |n| "game#{n}" }
    slack_team_id { "SLACKTEAMID" }
  end
end
