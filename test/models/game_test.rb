require 'test_helper'

class GameTest < ActiveSupport::TestCase
  context 'GameTest' do
    context '#for_slack_user_id' do
      context 'singles' do
        setup do
          @player1 = FactoryBot.create(:player1)
          @player2 = FactoryBot.create(:player2)
          @game = FactoryBot.create(:game, :with_slack_team_id, :draw, player_one: @player1, player_two: @player2)

          player3 = FactoryBot.create(:player3)
          player4 = FactoryBot.create(:player4)
          FactoryBot.create(:game, :with_slack_team_id, :draw, player_one: player3, player_two: player4)
        end

        context 'player_one' do
          should 'return only game for specified player' do
            result = Game.for_slack_user_id(@player1.slack_user_id)
            assert_equal 1, result.count
            assert_equal @game.id, result.take.id
          end
        end

        context 'player_two' do
          should 'return only game for specified player' do
            result = Game.for_slack_user_id(@player2.slack_user_id)
            assert_equal 1, result.count
            assert_equal @game.id, result.take.id
          end
        end
      end

      context 'doubles' do
        setup do
          @player1 = FactoryBot.create(:doubles_player1)
          @player2 = FactoryBot.create(:doubles_player2)
          @game = FactoryBot.create(:game, :with_slack_team_id, :draw, player_one: @player1, player_two: @player2)

          player3 = FactoryBot.create(:doubles_player3)
          player4 = FactoryBot.create(:doubles_player4)
          FactoryBot.create(:game, :with_slack_team_id, :draw, player_one: player3, player_two: player4)
        end

        context 'player_one' do
          should 'return only game for specified player' do
            result = Game.for_slack_user_id(@player1.slack_user_id)
            assert_equal 1, result.count
            assert_equal @game.id, result.take.id
          end

          should 'return game even if only one slack_user_id is specified' do
            result = Game.for_slack_user_id(@player1.slack_user_id.split('-').first)
            assert_equal 1, result.count
            assert_equal @game.id, result.take.id
          end
        end

        context 'player_two' do
          should 'return only game for specified player' do
            result = Game.for_slack_user_id(@player2.slack_user_id)
            assert_equal 1, result.count
            assert_equal @game.id, result.take.id
          end

          should 'return game even if only one slack_user_id is specified' do
            result = Game.for_slack_user_id(@player2.slack_user_id.split('-').first)
            assert_equal 1, result.count
            assert_equal @game.id, result.take.id
          end
        end
      end
    end

    context '#opponent' do
      setup do
        @player1 = FactoryBot.create(:player1)
        @player2 = FactoryBot.create(:player2)
        @player3 = FactoryBot.create(:player3)
        @game = FactoryBot.create(:game, :with_slack_team_id, :draw, player_one: @player1, player_two: @player2)
      end

      context 'player_one' do
        should 'return player_two' do
          assert_equal @player2.id, @game.opponent(@player1).id
        end
      end

      context 'player_two' do
        should 'return player_one' do
          assert_equal @player1.id, @game.opponent(@player2).id
        end
      end

      context 'other player' do
        should 'raise ArgumentError' do
          e = assert_raises(ArgumentError) do
            @game.opponent(@player3)
          end
          assert_equal 'player did not play in this game', e.message
        end
      end
    end

    context '#result_for' do
      setup do
        @player1 = FactoryBot.create(:player1)
        @player2 = FactoryBot.create(:player2)
      end

      context 'player_one wins' do
        setup do
          @game = FactoryBot.create(:game, :with_slack_team_id, :player_one_wins, player_one: @player1, player_two: @player2)
        end

        context 'player_one' do
          should 'return correct sentence' do
            expected = "#{@player1.team_tag} beat #{@player2.team_tag}"
            assert_equal expected, @game.result_for(@player1)
          end
        end

        context 'player_two' do
          should 'return correct sentence' do
            expected = "#{@player2.team_tag} lost to #{@player1.team_tag}"
            assert_equal expected, @game.result_for(@player2)
          end
        end
      end

      context 'player_one loses' do
        setup do
          @game = FactoryBot.create(:game, :with_slack_team_id, :player_one_loses, player_one: @player1, player_two: @player2)
        end

        context 'player_one' do
          should 'return correct sentence' do
            expected = "#{@player1.team_tag} lost to #{@player2.team_tag}"
            assert_equal expected, @game.result_for(@player1)
          end
        end

        context 'player_two' do
          should 'return correct sentence' do
            expected = "#{@player2.team_tag} beat #{@player1.team_tag}"
            assert_equal expected, @game.result_for(@player2)
          end
        end
      end

      context 'draw' do
        setup do
          @game = FactoryBot.create(:game, :with_slack_team_id, :draw, player_one: @player1, player_two: @player2)
        end

        context 'player_one' do
          should 'return correct sentence' do
            expected = "#{@player1.team_tag} tied #{@player2.team_tag}"
            assert_equal expected, @game.result_for(@player1)
          end
        end

        context 'player_two' do
          should 'return correct sentence' do
            expected = "#{@player2.team_tag} tied #{@player1.team_tag}"
            assert_equal expected, @game.result_for(@player2)
          end
        end
      end

      context 'other player' do
        setup do
          @player3 = FactoryBot.create(:player3)
          @game = FactoryBot.create(:game, :with_slack_team_id, :draw, player_one: @player1, player_two: @player2)
        end

        should 'raise ArgumentError' do
          e = assert_raises(ArgumentError) do
            @game.result_for(@player3)
          end
          assert_equal 'player did not play in this game', e.message
        end
      end
    end

    context '#result_response' do
      setup do
        @player1 = FactoryBot.create(:player1)
        @player1.rating = 1010
        @player2 = FactoryBot.create(:player2)
        @player2.rating = 920
      end

      context 'player_one wins' do
        setup do
          @game = FactoryBot.create(:game, :with_slack_team_id, :player_one_wins, player_one: @player1, player_two: @player2)
        end

        should 'return correct sentence' do
          result = @game.result_response
          expected = /^Congratulations to #{Regexp.escape(@player1.team_tag)} \(#{Regexp.escape(@player1.rating_change)}\) :(#{Emojis::POSITIVE.join(')|(')}): on defeating #{Regexp.escape(@player2.team_tag)} \(#{Regexp.escape(@player2.rating_change)}\) :(#{Emojis::NEGATIVE.join(')|(')}): at #{Regexp.escape(@game.game_type.game_name)}!$/
          assert_match expected, result
        end
      end

      context 'player_one loses' do
        setup do
          @game = FactoryBot.create(:game, :with_slack_team_id, :player_one_loses, player_one: @player1, player_two: @player2)
        end

        should 'return correct sentence' do
          result = @game.result_response
          expected = /^Congratulations to #{Regexp.escape(@player2.team_tag)} \(#{Regexp.escape(@player2.rating_change)}\) :(#{Emojis::POSITIVE.join(')|(')}): on defeating #{Regexp.escape(@player1.team_tag)} \(#{Regexp.escape(@player1.rating_change)}\) :(#{Emojis::NEGATIVE.join(')|(')}): at #{Regexp.escape(@game.game_type.game_name)}!$/
          assert_match expected, result
        end
      end

      context 'draw' do
        setup do
          @game = FactoryBot.create(:game, :with_slack_team_id, :draw, player_one: @player1, player_two: @player2)
        end

        should 'return correct sentence' do
          result = @game.result_response
          expected = /^#{Regexp.escape(@player1.team_tag)} \(#{Regexp.escape(@player1.rating_change)}\) :(#{Emojis::POSITIVE.join(')|(')}): tied #{Regexp.escape(@player2.team_tag)} \(#{Regexp.escape(@player2.rating_change)}\) :(#{Emojis::POSITIVE.join(')|(')}): at #{Regexp.escape(@game.game_type.game_name)}!$/
          assert_match expected, result
        end
      end
    end

    context '#set_extra_columns' do
      setup do
        @player1 = FactoryBot.create(:player1)
        @player2 = FactoryBot.create(:player2)
      end

      should 'set extra columns' do
        game = Game.create(player_one: @player1, player_two: @player2, result: 1, logged_by_slack_user_id: 'LOGGER')
        assert_equal @player1.slack_team_id, game.slack_team_id
        assert_equal @player1.slack_user_id, game.player_one_slack_user_id
        assert_equal @player2.slack_user_id, game.player_two_slack_user_id
        assert_equal @player1.game_type_id, game.game_type_id
        assert_equal @player1.team_size, game.team_size
      end
    end
  end
end
