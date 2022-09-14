FactoryBot.define do
  factory :game do
    sequence(:logged_by_slack_user_id) { |n| "LOGGER#{n}" }
    slack_team_id { 'SLACKTEAMID' }

    before(:create) do |game|
      game.game_type = game.player_one.game_type
      game.team_size = game.player_one.team_size
    end

    trait :player_one_wins do
      result { 1 }
    end

    trait :player_one_loses do
      result { 0 }
    end

    trait :draw do
      result { 0.5 }
    end
  end
end