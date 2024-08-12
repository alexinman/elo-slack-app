require 'test_helper'

class PlayerControllerTest < ActionController::TestCase
  context 'PlayerControllerTest' do
    setup do
      @params = {}

      @game_type1 = FactoryBot.create(:game_type)
      @game_type2 = FactoryBot.create(:game_type)

      @player1 = FactoryBot.create(:player1, game_type: @game_type1)
      @player2 = FactoryBot.create(:player2, game_type: @game_type1)
      @player3 = FactoryBot.create(:player1, game_type: @game_type2)
      @player4 = FactoryBot.create(:player2, game_type: @game_type2)
      @player5 = FactoryBot.create(:doubles_player1, game_type: @game_type1)
      @player6 = FactoryBot.create(:doubles_player2, game_type: @game_type1)
      @player7 = FactoryBot.create(:doubles_player1, game_type: @game_type2)
      @player8 = FactoryBot.create(:doubles_player2, game_type: @game_type2)
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
            @params.merge!({game_type_id: @game_type1.id})
          end

          context 'w/ team_size' do
            setup do
              @params.merge!({team_size: 1})
            end

            should 'return correct players' do
              get_players
              assert_json_response({
                                       'page' => 1,
                                       'per_page' => 10,
                                       'page_count' => 1,
                                       'item_count' => 1,
                                       'items' => [@player1].map(&:attributes).as_json
                                   })
            end
          end

          context 'w/o team_size' do
            should 'return correct players' do
              get_players
              assert_json_response({
                                       'page' => 1,
                                       'per_page' => 10,
                                       'page_count' => 1,
                                       'item_count' => 2,
                                       'items' => [@player1, @player5].map(&:attributes).as_json
                                   })
            end
          end
        end

        context 'w/o game_type_id' do
          context 'w/ team_size' do
            setup do
              @params.merge!({team_size: 1})
            end

            should 'return correct players' do
              get_players
              assert_json_response({
                                       'page' => 1,
                                       'per_page' => 10,
                                       'page_count' => 1,
                                       'item_count' => 2,
                                       'items' => [@player1, @player3].map(&:attributes).as_json
                                   })
            end
          end

          context 'w/o team_size' do
            should 'return correct players' do
              get_players
              assert_json_response({
                                       'page' => 1,
                                       'per_page' => 10,
                                       'page_count' => 1,
                                       'item_count' => 4,
                                       'items' => [@player1, @player3, @player5, @player7].map(&:attributes).as_json
                                   })
            end
          end
        end
      end

      context 'w/o slack_user_id' do
        context 'w/ game_type_id' do
          setup do
            @params.merge!({game_type_id: @game_type1.id})
          end

          context 'w/ team_size' do
            setup do
              @params.merge!({team_size: 1})
            end

            should 'return correct players' do
              get_players
              assert_json_response({
                                       'page' => 1,
                                       'per_page' => 10,
                                       'page_count' => 1,
                                       'item_count' => 2,
                                       'items' => [@player1, @player2].map(&:attributes).as_json
                                   })
            end
          end

          context 'w/o team_size' do
            should 'return correct players' do
              get_players
              assert_json_response({
                                       'page' => 1,
                                       'per_page' => 10,
                                       'page_count' => 1,
                                       'item_count' => 4,
                                       'items' => [@player1, @player2, @player5, @player6].map(&:attributes).as_json
                                   })
            end
          end
        end

        context 'w/o game_type_id' do
          context 'w/ team_size' do
            setup do
              @params.merge!({team_size: 1})
            end

            should 'return correct players' do
              get_players
              assert_json_response({
                                       'page' => 1,
                                       'per_page' => 10,
                                       'page_count' => 1,
                                       'item_count' => 4,
                                       'items' => [@player1, @player2, @player3, @player4].map(&:attributes).as_json
                                   })
            end
          end

          context 'w/o team_size' do
            should 'return correct players' do
              get_players
              assert_json_response({
                                       'page' => 1,
                                       'per_page' => 10,
                                       'page_count' => 1,
                                       'item_count' => 8,
                                       'items' => [@player1, @player2, @player3, @player4, @player5, @player6, @player7, @player8].map(&:attributes).as_json
                                   })
            end
          end
        end
      end
    end

    context 'w/o slack_team_id' do
      should 'return no players' do
        get_players
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

  def get_players
    get :players, params: @params
  end
end
