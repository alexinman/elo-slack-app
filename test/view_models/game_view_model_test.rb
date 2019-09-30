require 'test_helper'

class GameViewModelTest < ActiveSupport::TestCase
  SORT_ORDERS = [:updated_at, :created_at].freeze
  OPTIONAL_PARAMETERS = [:team_size].freeze

  context 'GameViewModelTest' do
    setup_basic_view_model_tests(SORT_ORDERS, OPTIONAL_PARAMETERS)

    context '#list' do
      context 'optional_parameter:slack_user_id' do
        setup do
          game_type = FactoryBot.create(:game_type, :with_slack_team_id)
          player1 = FactoryBot.create(:player1, game_type: game_type)
          player2 = FactoryBot.create(:player2, game_type: game_type)
          doubles_player1 = FactoryBot.create(:doubles_player2, game_type: game_type)
          doubles_player2 = FactoryBot.create(:doubles_player3, game_type: game_type)
          @game = FactoryBot.create(:game, player_one: player1, player_two: player2, result: 1)
          @doubles_game = FactoryBot.create(:game, player_one: doubles_player1, player_two: doubles_player2, result: 1)
        end

        context 'singles' do
          context 'player_one' do
            should 'return only game matching slack_user_id' do
              expected = {
                  page: 1,
                  per_page: 10,
                  page_count: 1,
                  item_count: 1,
                  items: [summary(@game)]
              }
              parameters = required_parameters.merge({slack_user_id: @game.player_one.slack_user_id})
              assert_equivalent expected, view_model.list(parameters).as_json.with_indifferent_access
            end
          end

          context 'player_two' do
            should 'return only game matching slack_user_id' do
              expected = {
                  page: 1,
                  per_page: 10,
                  page_count: 1,
                  item_count: 1,
                  items: [summary(@game)]
              }
              parameters = required_parameters.merge({slack_user_id: @game.player_two.slack_user_id})
              assert_equivalent expected, view_model.list(parameters).as_json.with_indifferent_access
            end
          end
        end

        context 'doubles' do
          context 'player_one' do
            should 'return only game matching slack_user_id' do
              expected = {
                  page: 1,
                  per_page: 10,
                  page_count: 1,
                  item_count: 1,
                  items: [summary(@doubles_game)]
              }
              parameters = required_parameters.merge({slack_user_id: 'PLAYER3'})
              assert_equivalent expected, view_model.list(parameters).as_json.with_indifferent_access
            end
          end

          context 'player_two' do
            should 'return only game matching slack_user_id' do
              expected = {
                  page: 1,
                  per_page: 10,
                  page_count: 1,
                  item_count: 1,
                  items: [summary(@doubles_game)]
              }
              parameters = required_parameters.merge({slack_user_id: 'PLAYER5'})
              assert_equivalent expected, view_model.list(parameters).as_json.with_indifferent_access
            end
          end
        end
      end

      context 'optional_parameter:game_type_id' do
        setup do
          @game_type1 = FactoryBot.create(:game_type, :with_slack_team_id)
          player1 = FactoryBot.create(:player1, game_type: @game_type1)
          player2 = FactoryBot.create(:player1, game_type: @game_type1)
          @game1 = FactoryBot.create(:game, player_one: player1, player_two: player2, result: 1)

          game_type2 = FactoryBot.create(:game_type, :with_slack_team_id)
          player1 = FactoryBot.create(:player1, game_type: game_type2)
          player2 = FactoryBot.create(:player1, game_type: game_type2)
          FactoryBot.create(:game, player_one: player1, player_two: player2, result: 1)
        end

        should 'return only game matching game_type_id' do
          expected = {
              page: 1,
              per_page: 10,
              page_count: 1,
              item_count: 1,
              items: [summary(@game1)]
          }
          parameters = required_parameters.merge({game_type_id: @game_type1.id})
          assert_equivalent expected, view_model.list(parameters).as_json.with_indifferent_access
        end
      end
    end

    context '#recent_games' do
      setup do
        game_type = FactoryBot.create(:game_type, :with_slack_team_id)
        @player1 = FactoryBot.create(:player1, game_type: game_type)
        @player2 = FactoryBot.create(:player2, game_type: game_type)
        @player3 = FactoryBot.create(:player3, game_type: game_type)

        @game1 = FactoryBot.create(:game, player_one: @player1, player_two: @player2, result: 1)
        @game2 = FactoryBot.create(:game, player_one: @player1, player_two: @player3, result: 1)
        FactoryBot.create(:game, player_one: @player2, player_two: @player3, result: 1)
      end

      should 'only return games relating to player' do
        expected = {
            page: 1,
            per_page: 5,
            page_count: 1,
            item_count: 2,
            items: [
                "• #{@game2.created_at.slack_format}: #{@game2.result_for(@player1)}",
                "• #{@game1.created_at.slack_format}: #{@game1.result_for(@player1)}"
            ]
        }
        assert_equivalent expected, view_model.recent_games(@player1).as_json.with_indifferent_access
      end

      context 'with more than 5 games' do
        setup do
          @game3 = FactoryBot.create(:game, player_one: @player1, player_two: @player3, result: 1)
          @game4 = FactoryBot.create(:game, player_one: @player1, player_two: @player3, result: 1)
          @game5 = FactoryBot.create(:game, player_one: @player1, player_two: @player3, result: 1)
          @game6 = FactoryBot.create(:game, player_one: @player1, player_two: @player3, result: 1)
        end

        should 'return only 5 most recent games' do
          expected = {
              page: 1,
              per_page: 5,
              page_count: 2,
              item_count: 6,
              items: [
                  "• #{@game6.created_at.slack_format}: #{@game6.result_for(@player1)}",
                  "• #{@game5.created_at.slack_format}: #{@game5.result_for(@player1)}",
                  "• #{@game4.created_at.slack_format}: #{@game4.result_for(@player1)}",
                  "• #{@game3.created_at.slack_format}: #{@game3.result_for(@player1)}",
                  "• #{@game2.created_at.slack_format}: #{@game2.result_for(@player1)}"
              ]
          }
          assert_equivalent expected, view_model.recent_games(@player1).as_json.with_indifferent_access
        end
      end
    end
  end

  def view_model
    GameViewModel
  end

  def model
    Game
  end

  def basic_object_attributes(slack_team_id = nil)
    slack_team_id ||= 'SLACKTEAMID'
    game_type = FactoryBot.create(:game_type, slack_team_id: slack_team_id)
    {
        slack_team_id: slack_team_id,
        player_one: FactoryBot.create(:player, :singles, slack_team_id: slack_team_id, slack_user_id: 'PLAYER1', game_type: game_type),
        player_two: FactoryBot.create(:player, :singles, slack_team_id: slack_team_id, slack_user_id: 'PLAYER2', game_type: game_type),
        result: 1
    }
  end
end