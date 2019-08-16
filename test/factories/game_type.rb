FactoryBot.define do
  factory :game_type do
    sequence(:game_name) { |n| "game#{n}" }

    trait :with_slack_team_id do
      slack_team_id { 'SLACKTEAMID' }
    end
  end
end