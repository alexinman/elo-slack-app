require 'test_helper'

class GameControllerTest < ActionController::TestCase
  context 'GameControllerTest' do
    setup do
      @game_type1 = FactoryBot.create(:game_type, :with_slack_team_id)
      @game_type2 = FactoryBot.create(:game_type, :with_slack_team_id)
    end

    context '#games' do
      setup do
        @player1 = FactoryBot.create(:player1, game_type: @game_type1)
        @player2 = FactoryBot.create(:player2, game_type: @game_type1)
        @game1 = FactoryBot.create(:game, player_one: @player1, player_two: @player2, result: 0)

        @player3 = FactoryBot.create(:player3, game_type: @game_type1)
        @player4 = FactoryBot.create(:player4, game_type: @game_type1)
        @game2 = FactoryBot.create(:game, player_one: @player3, player_two: @player4, result: 0.1)

        @player5 = FactoryBot.create(:player1, game_type: @game_type2)
        @player6 = FactoryBot.create(:player2, game_type: @game_type2)
        @game3 = FactoryBot.create(:game, player_one: @player5, player_two: @player6, result: 0.2)

        @player7 = FactoryBot.create(:player3, game_type: @game_type2)
        @player8 = FactoryBot.create(:player4, game_type: @game_type2)
        @game4 = FactoryBot.create(:game, player_one: @player7, player_two: @player8, result: 0.3)

        @player9 = FactoryBot.create(:doubles_player1, game_type: @game_type1)
        @player10 = FactoryBot.create(:doubles_player2, game_type: @game_type1)
        @game5 = FactoryBot.create(:game, player_one: @player9, player_two: @player10, result: 0.4)

        @player11 = FactoryBot.create(:doubles_player3, game_type: @game_type1)
        @player12 = FactoryBot.create(:doubles_player4, game_type: @game_type1)
        @game6 = FactoryBot.create(:game, player_one: @player11, player_two: @player12, result: 0.5)

        @player13 = FactoryBot.create(:doubles_player1, game_type: @game_type2)
        @player14 = FactoryBot.create(:doubles_player2, game_type: @game_type2)
        @game7 = FactoryBot.create(:game, player_one: @player13, player_two: @player14, result: 0.6)

        @player15 = FactoryBot.create(:doubles_player3, game_type: @game_type2)
        @player16 = FactoryBot.create(:doubles_player4, game_type: @game_type2)
        @game8 = FactoryBot.create(:game, player_one: @player15, player_two: @player16, result: 0.7)

        @params = {}
      end

      context 'w/ slack_team_id' do
        setup do
          @params.merge!({slack_team_id: 'SLACKTEAMID'})
        end

        context 'w/ slack_user_id' do
          setup do
            @params.merge!({slack_user_id: 'PLAYER1'})
          end

          context 'w/ game_type_id' do
            setup do
              @params.merge!(game_type_id: @game_type1.id)
            end

            context 'w/ team_size' do
              setup do
                @params.merge!(team_size: 1)
              end

              should 'return ok' do
                get_games
                assert_ok
              end

              should 'return matching games' do
                get_games
                assert_json_response({
                                         'page' => 1,
                                         'per_page' => 10,
                                         'page_count' => 1,
                                         'item_count' => 1,
                                         'items' => [@game1].map(&:attributes).as_json
                                     })
              end
            end

            context 'w/o team_size' do
              should 'return ok' do
                get_games
                assert_ok
              end

              should 'return matching games' do
                get_games
                assert_json_response({
                                         'page' => 1,
                                         'per_page' => 10,
                                         'page_count' => 1,
                                         'item_count' => 2,
                                         'items' => [@game1, @game5].map(&:attributes).as_json
                                     })
              end
            end
          end

          context 'w/o game_type_id' do
            context 'w/ team_size' do
              setup do
                @params.merge!(team_size: 1)
              end

              should 'return ok' do
                get_games
                assert_ok
              end

              should 'return matching games' do
                get_games
                assert_json_response({
                                         'page' => 1,
                                         'per_page' => 10,
                                         'page_count' => 1,
                                         'item_count' => 2,
                                         'items' => [@game1, @game3].map(&:attributes).as_json
                                     })
              end
            end

            context 'w/o team_size' do
              should 'return ok' do
                get_games
                assert_ok
              end

              should 'return matching games' do
                get_games
                assert_json_response({
                                         'page' => 1,
                                         'per_page' => 10,
                                         'page_count' => 1,
                                         'item_count' => 4,
                                         'items' => [@game1, @game3, @game5, @game7].map(&:attributes).as_json
                                     })
              end
            end
          end
        end

        context 'w/o slack_user_id' do
          context 'w/ game_type_id' do
            setup do
              @params.merge!(game_type_id: @game_type1.id)
            end

            context 'w/ team_size' do
              setup do
                @params.merge!(team_size: 1)
              end

              should 'return ok' do
                get_games
                assert_ok
              end

              should 'return matching games' do
                get_games
                assert_json_response({
                                         'page' => 1,
                                         'per_page' => 10,
                                         'page_count' => 1,
                                         'item_count' => 2,
                                         'items' => [@game1, @game2].map(&:attributes).as_json
                                     })
              end
            end

            context 'w/o team_size' do
              should 'return ok' do
                get_games
                assert_ok
              end

              should 'return matching games' do
                get_games
                assert_json_response({
                                         'page' => 1,
                                         'per_page' => 10,
                                         'page_count' => 1,
                                         'item_count' => 4,
                                         'items' => [@game1, @game2, @game5, @game6].map(&:attributes).as_json
                                     })
              end
            end
          end

          context 'w/o game_type_id' do
            context 'w/ team_size' do
              setup do
                @params.merge!(team_size: 1)
              end

              should 'return ok' do
                get_games
                assert_ok
              end

              should 'return matching games' do
                get_games
                assert_json_response({
                                         'page' => 1,
                                         'per_page' => 10,
                                         'page_count' => 1,
                                         'item_count' => 4,
                                         'items' => [@game1, @game2, @game3, @game4].map(&:attributes).as_json
                                     })
              end
            end

            context 'w/o team_size' do
              should 'return ok' do
                get_games
                assert_ok
              end

              should 'return matching games' do
                get_games
                assert_json_response({
                                         'page' => 1,
                                         'per_page' => 10,
                                         'page_count' => 1,
                                         'item_count' => 8,
                                         'items' => [@game1, @game2, @game3, @game4, @game5, @game6, @game7, @game8].map(&:attributes).as_json
                                     })
              end
            end
          end
        end
      end

      context 'w/o slack_team_id' do
        should 'return no results' do
          get_games
          assert_ok
          assert_json_response({
                                   'page' => 1,
                                   'per_page' => 10,
                                   'page_count' => 0,
                                   'item_count' => 0,
                                   'items' => []
                               })
        end
      end
    end

    context '#types' do
      setup do
        @game_type3 = FactoryBot.create(:game_type, slack_team_id: 'DIFFERENT')
        @game_type4 = FactoryBot.create(:game_type, slack_team_id: 'DIFFERENT')
        @params = {}
      end

      context 'w/ slack_team_id' do
        setup do
          @params.merge!({slack_team_id: 'SLACKTEAMID'})
        end

        should 'return game types' do
          get_types
          assert_ok
          assert_json_response({
                                   'page' => 1,
                                   'per_page' => 10,
                                   'page_count' => 1,
                                   'item_count' => 2,
                                   'items' => [@game_type1, @game_type2].map(&:attributes).as_json
                               })
        end
      end

      context 'w/o slack_team_id' do
        should 'return empty list' do
          get_types
          assert_ok
          assert_json_response({
                                   'page' => 1,
                                   'per_page' => 10,
                                   'page_count' => 0,
                                   'item_count' => 0,
                                   'items' => []
                               })
        end
      end
    end
  end

  def get_games
    get :games, @params
  end

  def get_types
    get :types, @params
  end
end