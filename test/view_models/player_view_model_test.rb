require 'test_helper'

class PlayerViewModelTest < ActiveSupport::TestCase
  SORT_ORDERS = [:team_size, :updated_at, :created_at, :rating].freeze
  OPTIONAL_PARAMETERS = [:team_size].freeze

  context 'PlayerViewModelTest' do
    setup_basic_view_model_tests(SORT_ORDERS, OPTIONAL_PARAMETERS)

    context '#list' do
      context 'optional_parameter:slack_user_id' do
        setup do
          game_type = FactoryBot.create(:game_type)
          @player1 = FactoryBot.create(:player1, game_type: game_type)
          _player2 = FactoryBot.create(:player2, game_type: game_type)
          @doubles_player1 = FactoryBot.create(:doubles_player1, game_type: game_type)
          _doubles_player2 = FactoryBot.create(:doubles_player2, game_type: game_type)
        end

        should 'only return Players matching provided slack_user_id' do
          expected = {
              page: 1,
              per_page: 10,
              page_count: 1,
              item_count: 2,
              items: [summary(@player1), summary(@doubles_player1)]
          }
          parameters = required_parameters.merge({slack_user_id: @player1.slack_user_id})
          assert_equivalent expected, view_model.list(parameters).as_json.with_indifferent_access
        end
      end

      context 'optional_parameter:game_type_id' do
        setup do
          @game_type = FactoryBot.create(:game_type)
          @player1 = FactoryBot.create(:player1, game_type: @game_type)
          @player2 = FactoryBot.create(:player2, game_type: @game_type)
          other_game_type = FactoryBot.create(:game_type)
          _other_player1 = FactoryBot.create(:player1, game_type: other_game_type)
          _other_player2 = FactoryBot.create(:player2, game_type: other_game_type)
        end

        should 'only return Players matching provided game_type_id' do
          expected = {
              page: 1,
              per_page: 10,
              page_count: 1,
              item_count: 2,
              items: [summary(@player1), summary(@player2)]
          }
          parameters = required_parameters.merge({game_type_id: @game_type.id})
          assert_equivalent expected, view_model.list(parameters).as_json.with_indifferent_access
        end
      end
    end

    context '#statistics' do
      setup do
        @game_type1 = FactoryBot.create(:game_type)
        @game_type2 = FactoryBot.create(:game_type)

        @p1_gt1 = FactoryBot.create(:player1, game_type: @game_type1, rating: 100)
        @p1_gt2 = FactoryBot.create(:player1, game_type: @game_type2, rating: 110)

        @p2_gt1 = FactoryBot.create(:player2, game_type: @game_type1, rating: 200)
        @p2_gt2 = FactoryBot.create(:player2, game_type: @game_type2, rating: 210)

        @dp1_gt1 = FactoryBot.create(:doubles_player1, game_type: @game_type1, rating: 300)
        @dp1_gt2 = FactoryBot.create(:doubles_player1, game_type: @game_type2, rating: 310)

        @dp2_gt1 = FactoryBot.create(:player, :doubles, slack_user_id: '@PLAYER1-@PLAYER3', game_type: @game_type1, rating: 400)
        @dp2_gt2 = FactoryBot.create(:player, :doubles, slack_user_id: '@PLAYER1-@PLAYER3', game_type: @game_type2, rating: 410)

        FactoryBot.create(:player1, slack_team_id: 'DIFFERENT', game_type: @game_type1)

        Timecop.freeze
      end

      teardown do
        Timecop.return
      end

      should 'return no items if slack_team_id is not provided' do
        expected = {items: []}
        actual = view_model.statistics(slack_user_id: '@PLAYER1').as_json.with_indifferent_access
        assert_equivalent expected, actual
      end

      should 'return no items if slack_user_id is not provided' do
        expected = {items: []}
        actual = view_model.statistics(slack_team_id: 'SLACKTEAMID').as_json.with_indifferent_access
        assert_equivalent expected, actual
      end

      should 'return all Players matching slack_user_id and slack_team_id' do
        expected = {
            items: [
                {
                    title: '<@PLAYER1>',
                    fallback: 'Elo rating: 100',
                    fields: [
                        {
                            title: 'Rank',
                            value: "1. <@PLAYER2> (200)\n2. <@PLAYER1> (100)",
                            short: false
                        },
                        {
                            title: 'Wins',
                            value: 0,
                            short: true
                        },
                        {
                            title: 'Losses',
                            value: 0,
                            short: true
                        },
                        {
                            title: 'Recent Games',
                            value: '',
                            short: false
                        }
                    ],
                    footer: @game_type1.game_name.titleize,
                    footer_icon: 'http://localhost:3000/images/baseline_person_black_18dp.png',
                    ts: Time.now.to_i
                },
                {
                    title: '<@PLAYER1>',
                    fallback: 'Elo rating: 110',
                    fields: [
                        {
                            title: 'Rank',
                            value: "1. <@PLAYER2> (210)\n2. <@PLAYER1> (110)",
                            short: false
                        },
                        {
                            title: 'Wins',
                            value: 0,
                            short: true
                        },
                        {
                            title: 'Losses',
                            value: 0,
                            short: true
                        },
                        {
                            title: 'Recent Games',
                            value: '',
                            short: false
                        }
                    ],
                    footer: @game_type2.game_name.titleize,
                    footer_icon: 'http://localhost:3000/images/baseline_person_black_18dp.png',
                    ts: Time.now.to_i
                },
                {
                    title: '<@PLAYER1>',
                    fallback: 'Elo rating: 350',
                    fields: [
                        {
                            title: 'Average Rating',
                            value: 350,
                            short: false
                        },
                        {
                            title: 'Wins',
                            value: 0,
                            short: true
                        },
                        {
                            title: 'Losses',
                            value: 0,
                            short: true
                        },
                        {
                            title: 'Recent Games',
                            value: '',
                            short: false
                        }
                    ],
                    footer: @game_type1.game_name.titleize,
                    footer_icon: 'http://localhost:3000/images/baseline_people_black_18dp.png',
                    ts: Time.now.to_i
                },
                {
                    title: '<@PLAYER1>',
                    fallback: 'Elo rating: 360',
                    fields: [
                        {
                            title: 'Average Rating',
                            value: 360,
                            short: false
                        },
                        {
                            title: 'Wins',
                            value: 0,
                            short: true
                        },
                        {
                            title: 'Losses',
                            value: 0,
                            short: true
                        },
                        {
                            title: 'Recent Games',
                            value: '',
                            short: false
                        }
                    ],
                    footer: @game_type2.game_name.titleize,
                    footer_icon: 'http://localhost:3000/images/baseline_people_black_18dp.png',
                    ts: Time.now.to_i
                }
            ]
        }
        actual = view_model.statistics(slack_team_id: 'SLACKTEAMID', slack_user_id: '@PLAYER1').as_json.with_indifferent_access
        assert_equivalent expected, actual
      end

      context 'optional_parameter:game_type_id' do
        should 'only return Players matching game_type_id' do
          expected = {
              items: [
                  {
                      title: '<@PLAYER1>',
                      fallback: 'Elo rating: 100',
                      fields: [
                          {
                              title: 'Rank',
                              value: "1. <@PLAYER2> (200)\n2. <@PLAYER1> (100)",
                              short: false
                          },
                          {
                              title: 'Wins',
                              value: 0,
                              short: true
                          },
                          {
                              title: 'Losses',
                              value: 0,
                              short: true
                          },
                          {
                              title: 'Recent Games',
                              value: '',
                              short: false
                          }
                      ],
                      footer: @game_type1.game_name.titleize,
                      footer_icon: 'http://localhost:3000/images/baseline_person_black_18dp.png',
                      ts: Time.now.to_i
                  },
                  {
                      title: '<@PLAYER1>',
                      fallback: 'Elo rating: 350',
                      fields: [
                          {
                              title: 'Average Rating',
                              value: 350,
                              short: false
                          },
                          {
                              title: 'Wins',
                              value: 0,
                              short: true
                          },
                          {
                              title: 'Losses',
                              value: 0,
                              short: true
                          },
                          {
                              title: 'Recent Games',
                              value: '',
                              short: false
                          }
                      ],
                      footer: @game_type1.game_name.titleize,
                      footer_icon: 'http://localhost:3000/images/baseline_people_black_18dp.png',
                      ts: Time.now.to_i
                  }
              ]
          }
          actual = view_model.statistics(slack_team_id: 'SLACKTEAMID', slack_user_id: '@PLAYER1', game_type_id: @game_type1.id).as_json.with_indifferent_access
          assert_equivalent expected, actual
        end
      end

      context 'optional_parameter:team_size' do
        should 'only return Players matching team_size' do
          expected = {
              items: [
                  {
                      title: '<@PLAYER1>',
                      fallback: 'Elo rating: 100',
                      fields: [
                          {
                              title: 'Rank',
                              value: "1. <@PLAYER2> (200)\n2. <@PLAYER1> (100)",
                              short: false
                          },
                          {
                              title: 'Wins',
                              value: 0,
                              short: true
                          },
                          {
                              title: 'Losses',
                              value: 0,
                              short: true
                          },
                          {
                              title: 'Recent Games',
                              value: '',
                              short: false
                          }
                      ],
                      footer: @game_type1.game_name.titleize,
                      footer_icon: 'http://localhost:3000/images/baseline_person_black_18dp.png',
                      ts: Time.now.to_i
                  },
                  {
                      title: '<@PLAYER1>',
                      fallback: 'Elo rating: 110',
                      fields: [
                          {
                              title: 'Rank',
                              value: "1. <@PLAYER2> (210)\n2. <@PLAYER1> (110)",
                              short: false
                          },
                          {
                              title: 'Wins',
                              value: 0,
                              short: true
                          },
                          {
                              title: 'Losses',
                              value: 0,
                              short: true
                          },
                          {
                              title: 'Recent Games',
                              value: '',
                              short: false
                          }
                      ],
                      footer: @game_type2.game_name.titleize,
                      footer_icon: 'http://localhost:3000/images/baseline_person_black_18dp.png',
                      ts: Time.now.to_i
                  }
              ]
          }
          actual = view_model.statistics(slack_team_id: 'SLACKTEAMID', slack_user_id: '@PLAYER1', team_size: 1).as_json.with_indifferent_access
          assert_equivalent expected, actual
        end
      end

      context 'all optional parameters' do
        should 'only return Players matching all parameters' do
          expected = {
              items: [
                  {
                      title: '<@PLAYER1>',
                      fallback: 'Elo rating: 100',
                      fields: [
                          {
                              title: 'Rank',
                              value: "1. <@PLAYER2> (200)\n2. <@PLAYER1> (100)",
                              short: false
                          },
                          {
                              title: 'Wins',
                              value: 0,
                              short: true
                          },
                          {
                              title: 'Losses',
                              value: 0,
                              short: true
                          },
                          {
                              title: 'Recent Games',
                              value: '',
                              short: false
                          }
                      ],
                      footer: @game_type1.game_name.titleize,
                      footer_icon: 'http://localhost:3000/images/baseline_person_black_18dp.png',
                      ts: Time.now.to_i
                  }
              ]
          }
          actual = view_model.statistics(slack_team_id: 'SLACKTEAMID', slack_user_id: '@PLAYER1', game_type_id: @game_type1.id, team_size: 1).as_json.with_indifferent_access
          assert_equivalent expected, actual
        end
      end

      context 'with more than 0 wins' do
        setup do
          FactoryBot.create(:game, player_one: @p1_gt1, player_two: @p2_gt1, game_type: @game_type1, result: 1)
        end

        should 'return correct number of wins' do
          expected = {
              items: [
                  {
                      title: '<@PLAYER1>',
                      fallback: 'Elo rating: 100',
                      fields: [
                          {
                              title: 'Rank',
                              value: "1. <@PLAYER2> (200)\n2. <@PLAYER1> (100)",
                              short: false
                          },
                          {
                              title: 'Wins',
                              value: 1,
                              short: true
                          },
                          {
                              title: 'Losses',
                              value: 0,
                              short: true
                          },
                          {
                              title: 'Recent Games',
                              value: /<@PLAYER1> beat <@PLAYER2>/,
                              short: false
                          }
                      ],
                      footer: @game_type1.game_name.titleize,
                      footer_icon: 'http://localhost:3000/images/baseline_person_black_18dp.png',
                      ts: Time.now.to_i
                  }
              ]
          }
          actual = view_model.statistics(slack_team_id: 'SLACKTEAMID', slack_user_id: '@PLAYER1', game_type_id: @game_type1.id, team_size: 1).as_json.with_indifferent_access
          assert_equivalent expected, actual
        end
      end

      context 'with more than 0 losses' do
        setup do
          FactoryBot.create(:game, player_one: @p1_gt1, player_two: @p2_gt1, game_type: @game_type1, result: 0)
        end

        should 'return correct number of losses' do
          expected = {
              items: [
                  {
                      title: '<@PLAYER1>',
                      fallback: 'Elo rating: 100',
                      fields: [
                          {
                              title: 'Rank',
                              value: "1. <@PLAYER2> (200)\n2. <@PLAYER1> (100)",
                              short: false
                          },
                          {
                              title: 'Wins',
                              value: 0,
                              short: true
                          },
                          {
                              title: 'Losses',
                              value: 1,
                              short: true
                          },
                          {
                              title: 'Recent Games',
                              value: /<@PLAYER1> lost to <@PLAYER2>/,
                              short: false
                          }
                      ],
                      footer: @game_type1.game_name.titleize,
                      footer_icon: 'http://localhost:3000/images/baseline_person_black_18dp.png',
                      ts: Time.now.to_i
                  }
              ]
          }
          actual = view_model.statistics(slack_team_id: 'SLACKTEAMID', slack_user_id: '@PLAYER1', game_type_id: @game_type1.id, team_size: 1).as_json.with_indifferent_access
          assert_equivalent expected, actual
        end
      end

      context 'with more than 0 ties' do
        setup do
          FactoryBot.create(:game, player_one: @p1_gt1, player_two: @p2_gt1, game_type: @game_type1, result: 0.5)
        end

        should 'return correct number of ties' do
          expected = {
              items: [
                  {
                      title: '<@PLAYER1>',
                      fallback: 'Elo rating: 100',
                      fields: [
                          {
                              title: 'Rank',
                              value: "1. <@PLAYER2> (200)\n2. <@PLAYER1> (100)",
                              short: false
                          },
                          {
                              title: 'Wins',
                              value: 0,
                              short: true
                          },
                          {
                              title: 'Losses',
                              value: 0,
                              short: true
                          },
                          {
                              title: 'Ties',
                              value: 1,
                              short: true
                          },
                          {
                              title: 'Recent Games',
                              value: /<@PLAYER1> tied <@PLAYER2>/,
                              short: false
                          }
                      ],
                      footer: @game_type1.game_name.titleize,
                      footer_icon: 'http://localhost:3000/images/baseline_person_black_18dp.png',
                      ts: Time.now.to_i
                  }
              ]
          }
          actual = view_model.statistics(slack_team_id: 'SLACKTEAMID', slack_user_id: '@PLAYER1', game_type_id: @game_type1.id, team_size: 1).as_json.with_indifferent_access
          assert_equivalent expected, actual
        end
      end

      context 'with Nemesis' do
        setup do
          FactoryBot.create(:game, player_one: @p1_gt1, player_two: @p2_gt1, game_type: @game_type1, result: 0)
          FactoryBot.create(:game, player_one: @p1_gt1, player_two: @p2_gt1, game_type: @game_type1, result: 0)
          FactoryBot.create(:game, player_one: @p1_gt1, player_two: @p2_gt1, game_type: @game_type1, result: 0)
          FactoryBot.create(:game, player_one: @p1_gt1, player_two: @p2_gt1, game_type: @game_type1, result: 0)
        end

        should 'return correct number of ties' do
          expected = {
              items: [
                  {
                      title: '<@PLAYER1>',
                      fallback: 'Elo rating: 100',
                      fields: [
                          {
                              title: 'Rank',
                              value: "1. <@PLAYER2> (200)\n2. <@PLAYER1> (100)",
                              short: false
                          },
                          {
                              title: 'Wins',
                              value: 0,
                              short: true
                          },
                          {
                              title: 'Losses',
                              value: 4,
                              short: true
                          },
                          {
                              title: 'Nemesis',
                              value: '<@PLAYER2>',
                              short: false
                          },
                          :any
                      ],
                      footer: @game_type1.game_name.titleize,
                      footer_icon: 'http://localhost:3000/images/baseline_person_black_18dp.png',
                      ts: Time.now.to_i
                  }
              ]
          }
          actual = view_model.statistics(slack_team_id: 'SLACKTEAMID', slack_user_id: '@PLAYER1', game_type_id: @game_type1.id, team_size: 1).as_json.with_indifferent_access
          assert_equivalent expected, actual
        end
      end
    end
  end

  def view_model
    PlayerViewModel
  end

  def model
    Player
  end

  def basic_object_attributes(slack_team_id = nil)
    slack_team_id ||= 'SLACKTEAMID'
    game_type = FactoryBot.create(:game_type, slack_team_id: slack_team_id)
    {
        slack_team_id: slack_team_id,
        game_type: game_type,
        team_size: 1,
        slack_user_id: 'PLAYER1'
    }
  end
end