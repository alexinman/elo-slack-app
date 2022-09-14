FactoryBot.define do
  factory :player do
    slack_team_id { 'SLACKTEAMID' }

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

    trait :singles do
      team_size { 1 }
    end

    trait :doubles do
      team_size { 2 }
    end

    trait :with_singles_user_id do
      sequence(:slack_user_id) { |n| "@PLAYER#{n}" }
    end

    trait :with_doubles_user_id do
      sequence(:slack_user_id) { |n| "@PLAYER#{n*2}-@PLAYER#{n*2+1}" }
    end

    factory :player1, traits: [:with_p1_user_id, :singles]
    factory :player2, traits: [:with_p2_user_id, :singles]
    factory :player3, traits: [:with_p3_user_id, :singles]
    factory :player4, traits: [:with_p4_user_id, :singles]

    factory :doubles_player1, traits: [:with_doubles_p1_user_id, :doubles]
    factory :doubles_player2, traits: [:with_doubles_p2_user_id, :doubles]
    factory :doubles_player3, traits: [:with_doubles_p3_user_id, :doubles]
    factory :doubles_player4, traits: [:with_doubles_p4_user_id, :doubles]
  end
end