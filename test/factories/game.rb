FactoryBot.define do
  factory :game do
    sequence(:logged_by_slack_user_id) { |n| "LOGGER#{n}" }

    trait :with_slack_team_id do
      slack_team_id { 'SLACKTEAMID' }
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