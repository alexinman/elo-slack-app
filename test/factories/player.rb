FactoryBot.define do
  factory :player do
    trait :with_slack_team_id do
      slack_team_id { 'SLACKTEAMID' }
    end

    trait :with_p1_user_id do
      slack_user_id { '@PLAYER1' }
    end

    trait :with_p2_user_id do
      slack_user_id { '@PLAYER2' }
    end

    trait :with_p3_user_id do
      slack_user_id { '@PLAYER3' }
    end

    trait :with_p4_user_id do
      slack_user_id { '@PLAYER4' }
    end

    trait :with_doubles_p1_user_id do
      slack_user_id { '@PLAYER1-@PLAYER2' }
    end

    trait :with_doubles_p2_user_id do
      slack_user_id { '@PLAYER3-@PLAYER4' }
    end

    trait :with_doubles_p3_user_id do
      slack_user_id { '@PLAYER5-@PLAYER6' }
    end

    trait :with_doubles_p4_user_id do
      slack_user_id { '@PLAYER7-@PLAYER8' }
    end

    trait :with_game_type do
      id = FactoryBot.create(:game_type, :with_slack_team_id).id
      game_type_id { id }
    end

    trait :singles do
      team_size { 1 }
    end

    trait :doubles do
      team_size { 2 }
    end

    factory :player1, traits: [:with_slack_team_id, :with_p1_user_id, :with_game_type, :singles]
    factory :player2, traits: [:with_slack_team_id, :with_p2_user_id, :with_game_type, :singles]
    factory :player3, traits: [:with_slack_team_id, :with_p3_user_id, :with_game_type, :singles]
    factory :player4, traits: [:with_slack_team_id, :with_p4_user_id, :with_game_type, :singles]

    factory :doubles_player1, traits: [:with_slack_team_id, :with_doubles_p1_user_id, :with_game_type, :doubles]
    factory :doubles_player2, traits: [:with_slack_team_id, :with_doubles_p2_user_id, :with_game_type, :doubles]
    factory :doubles_player3, traits: [:with_slack_team_id, :with_doubles_p3_user_id, :with_game_type, :doubles]
    factory :doubles_player4, traits: [:with_slack_team_id, :with_doubles_p4_user_id, :with_game_type, :doubles]
  end
end