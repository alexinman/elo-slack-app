require 'test_helper'

class PlayerTest < ActiveSupport::TestCase
  context 'PlayerTest' do
    context '#for_slack_user_id' do
      context 'singles' do
        setup do
          @player = FactoryBot.create(:player1)
          FactoryBot.create(:player2)
          FactoryBot.create(:player3)
        end

        should 'return only specified player' do
          result = Player.for_slack_user_id(@player.slack_user_id)
          assert_equal 1, result.count
          assert_equal @player.id, result.take.id
        end
      end

      context 'doubles' do
        setup do
          @player = FactoryBot.create(:doubles_player1)
          FactoryBot.create(:doubles_player2)
          FactoryBot.create(:doubles_player3)
        end

        should 'return only specified player' do
          result = Player.for_slack_user_id(@player.slack_user_id)
          assert_equal 1, result.count
          assert_equal @player.id, result.take.id
        end

        should 'return player even if only one slack_user_id is specified' do
          result = Player.for_slack_user_id(@player.slack_user_id.split('-').first)
          assert_equal 1, result.count
          assert_equal @player.id, result.take.id
        end
      end
    end

    context '#games' do
      context 'unsaved Player' do
        setup do
          @player1 = Player.new
        end

        should 'return empty relation' do
          assert_empty @player1.games
        end
      end

      context 'saved Player' do
        setup do
          @player1 = FactoryBot.create(:player1)
          @player2 = FactoryBot.create(:player2)
        end

        context 'no games' do
          should 'return empty relation' do
            assert_empty @player1.games
          end
        end

        context 'with game' do
          context 'win' do
            context 'player_one' do
              setup do
                @game = FactoryBot.create(:game, :with_slack_team_id, player_one_id: @player1.id, player_two_id: @player2.id, result: 1)
              end

              should 'return game' do
                result = @player1.games
                assert_equal 1, result.count
                assert_equal @game.id, result.take.id
              end
            end

            context 'player_two' do
              setup do
                @game = FactoryBot.create(:game, :with_slack_team_id, player_one_id: @player2.id, player_two_id: @player1.id, result: 0)
              end

              should 'return game' do
                result = @player1.games
                assert_equal 1, result.count
                assert_equal @game.id, result.take.id
              end
            end
          end

          context 'loss' do
            context 'player_one' do
              setup do
                @game = FactoryBot.create(:game, :with_slack_team_id, player_one_id: @player1.id, player_two_id: @player2.id, result: 0)
              end

              should 'return game' do
                result = @player1.games
                assert_equal 1, result.count
                assert_equal @game.id, result.take.id
              end
            end

            context 'player_two' do
              setup do
                @game = FactoryBot.create(:game, :with_slack_team_id, player_one_id: @player2.id, player_two_id: @player1.id, result: 1)
              end

              should 'return game' do
                result = @player1.games
                assert_equal 1, result.count
                assert_equal @game.id, result.take.id
              end
            end
          end

          context 'tie' do
            context 'player_one' do
              setup do
                @game = FactoryBot.create(:game, :with_slack_team_id, player_one_id: @player1.id, player_two_id: @player2.id, result: 0.5)
              end

              should 'return game' do
                result = @player1.games
                assert_equal 1, result.count
                assert_equal @game.id, result.take.id
              end
            end

            context 'player_two' do
              setup do
                @game = FactoryBot.create(:game, :with_slack_team_id, player_one_id: @player2.id, player_two_id: @player1.id, result: 0.5)
              end

              should 'return game' do
                result = @player1.games
                assert_equal 1, result.count
                assert_equal @game.id, result.take.id
              end
            end
          end
        end

        context 'game from another slack team' do
          setup do
            game = FactoryBot.create(:game, player_one_id: @player1.id, player_two_id: @player2.id, result: 1)
            game.update_column(:slack_team_id, 'DIFFERENT')
          end

          should 'return empty relation' do
            assert_empty @player1.games
          end
        end

        context 'game from another game type' do
          setup do
            game_type = FactoryBot.create(:game_type, :with_slack_team_id)
            game = FactoryBot.create(:game, player_one_id: @player1.id, player_two_id: @player2.id, result: 1)
            game.update_column(:game_type_id, game_type.id)
          end

          should 'return empty relation' do
            assert_empty @player1.games
          end
        end

        context 'game with a different team size' do
          setup do
            game = FactoryBot.create(:game, player_one_id: @player1.id, player_two_id: @player2.id, result: 1)
            game.update_column(:team_size, 2)
          end

          should 'return empty relation' do
            assert_empty @player1.games
          end
        end

        context 'game for another player' do
          setup do
            player3 = FactoryBot.create(:player3)
            FactoryBot.create(:game, player_one_id: player3.id, player_two_id: @player2.id, result: 1)
          end

          should 'return empty relation' do
            assert_empty @player1.games
          end
        end
      end

      context 'doubles player' do
        setup do
          @doubles_player1 = FactoryBot.create(:doubles_player1)
          doubles_player2 = FactoryBot.create(:doubles_player2)
          @game = FactoryBot.create(:game, player_one_id: @doubles_player1.id, player_two_id: doubles_player2.id, result: 1)
        end

        should 'return game' do
          result = @doubles_player1.games
          assert_equal 1, result.count
          assert_equal @game.id, result.take.id
        end
      end
    end

    context '#elo_player' do
      context 'new Player' do
        setup do
          @player = Player.new
        end

        should 'return Elo::Player with default rating' do
          result = @player.elo_player
          assert_equal 1000, result.rating
        end

        should 'return Elo::Player with 0 games_played' do
          result = @player.elo_player
          assert_equal 0, result.games_played
        end
      end

      context 'existing Player' do
        setup do
          @player = FactoryBot.create(:player1, rating: 571)
        end

        should 'return Elo::Player with Player rating' do
          result = @player.elo_player
          assert_equal @player.rating, result.rating
        end

        should 'return Elo::Player with 0 games_played' do
          result = @player.elo_player
          assert_equal 0, result.games_played
        end

        context 'with games' do
          setup do
            player2 = FactoryBot.create(:player2)
            FactoryBot.create(:game, :with_slack_team_id, player_one_id: @player.id, player_two_id: player2.id, result: 1)
            FactoryBot.create(:game, :with_slack_team_id, player_one_id: player2.id, player_two_id: @player.id, result: 1)
            FactoryBot.create(:game, :with_slack_team_id, player_one_id: @player.id, player_two_id: player2.id, result: 0)
            FactoryBot.create(:game, :with_slack_team_id, player_one_id: player2.id, player_two_id: @player.id, result: 0)
            FactoryBot.create(:game, :with_slack_team_id, player_one_id: @player.id, player_two_id: player2.id, result: 0.5)
            FactoryBot.create(:game, :with_slack_team_id, player_one_id: player2.id, player_two_id: @player.id, result: 0.5)

            player3 = FactoryBot.create(:player3)
            FactoryBot.create(:game, :with_slack_team_id, player_one_id: player3.id, player_two_id: player2.id, result: 1)
            FactoryBot.create(:game, :with_slack_team_id, player_one_id: player2.id, player_two_id: player3.id, result: 1)
            FactoryBot.create(:game, :with_slack_team_id, player_one_id: player3.id, player_two_id: player2.id, result: 0)
            FactoryBot.create(:game, :with_slack_team_id, player_one_id: player2.id, player_two_id: player3.id, result: 0)
            FactoryBot.create(:game, :with_slack_team_id, player_one_id: player3.id, player_two_id: player2.id, result: 0.5)
            FactoryBot.create(:game, :with_slack_team_id, player_one_id: player2.id, player_two_id: player3.id, result: 0.5)
          end

          should 'return Elo::Player with Player rating' do
            result = @player.elo_player
            assert_equal @player.rating, result.rating
          end

          should 'return Elo::Player with 6 games_played' do
            result = @player.elo_player
            assert_equal 6, result.games_played
          end
        end
      end
    end

    context '#team_tag' do
      context 'singles' do
        setup do
          @player = FactoryBot.create(:player1)
        end

        should 'return slack formatted team tag' do
          assert_equal "<#{@player.slack_user_id}>", @player.team_tag
        end
      end

      context 'doubles' do
        setup do
          @player = FactoryBot.create(:doubles_player1)
        end

        should 'return slack formatted team tag' do
          id1, id2 = @player.slack_user_id.split('-')
          assert_equal "<#{id1}> and <#{id2}>", @player.team_tag
        end
      end

      context 'triples' do
        setup do
          @player = FactoryBot.create(:player, :with_slack_team_id, :with_game_type, slack_user_id: '@PLAYER1-@PLAYER2-@PLAYER3', team_size: 3)
        end

        should 'return slack formatted team tag' do
          id1, id2, id3 = @player.slack_user_id.split('-')
          assert_equal "<#{id1}>, <#{id2}>, and <#{id3}>", @player.team_tag
        end
      end
    end

    context '#doubles?' do
      context 'singles player' do
        setup do
          @player = FactoryBot.create(:player1)
        end

        should 'return false' do
          assert !@player.doubles?
        end
      end

      context 'doubles player' do
        setup do
          @player = FactoryBot.create(:doubles_player1)
        end

        should 'return true' do
          assert @player.doubles?
        end
      end
    end

    context '#doubles_individual?' do
      context 'singles player' do
        setup do
          @player = FactoryBot.create(:player1)
        end

        should 'return false' do
          assert !@player.doubles_individual?
        end
      end

      context 'doubles player' do
        setup do
          @player = FactoryBot.create(:doubles_player1)
        end

        should 'return false' do
          assert !@player.doubles_individual?
        end
      end

      context 'doubles individual player' do
        setup do
          @player = FactoryBot.create(:doubles_player1)
          @player.slack_user_id = '@PLAYER1'
        end

        should 'return true' do
          assert @player.doubles_individual?
        end
      end
    end

    context '#rating_change' do
      context 'no change' do
        setup do
          @player = Player.new
        end

        should 'return +0' do
          assert_equal '+0', @player.rating_change
        end
      end

      context 'with positive change' do
        setup do
          @player = FactoryBot.create(:player1)
          @player.rating = @player.rating + 10
        end

        should 'return +10' do
          assert_equal '+10', @player.rating_change
        end
      end

      context 'with negative change' do
        setup do
          @player = FactoryBot.create(:player1)
          @player.rating = @player.rating - 10
        end

        should 'return -10' do
          assert_equal '-10', @player.rating_change
        end
      end
    end

    context '#number_of_wins' do
      setup do
        @player = FactoryBot.create(:player1)
        @other_player = FactoryBot.create(:player2)
      end

      context 'with no games' do
        should 'return 0' do
          assert_equal 0, @player.number_of_wins
        end
      end

      context 'with game' do
        context 'as player_one' do
          setup do
            @player1 = @player
            @player2 = @other_player
          end

          context 'win' do
            setup do
              @game = FactoryBot.create(:game, :with_slack_team_id, result: 1, player_one_id: @player1.id, player_two_id: @player2.id)
            end

            should 'return 1' do
              assert_equal 1, @player.number_of_wins
            end

            context 'game is for another slack team' do
              setup do
                @game.update_column(:slack_team_id, 'DIFFERENT')
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_wins
              end
            end

            context 'game is for another team_size' do
              setup do
                @game.update_column(:team_size, 2)
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_wins
              end
            end

            context 'game is for another game type' do
              setup do
                game_type = FactoryBot.create(:game_type, :with_slack_team_id)
                @game.update_column(:game_type_id, game_type.id)
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_wins
              end
            end
          end

          context 'loss' do
            setup do
              @game = FactoryBot.create(:game, :with_slack_team_id, result: 0, player_one_id: @player1.id, player_two_id: @player2.id)
            end

            should 'return 0' do
              assert_equal 0, @player.number_of_wins
            end

            context 'game is for another slack team' do
              setup do
                @game.update_column(:slack_team_id, 'DIFFERENT')
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_wins
              end
            end

            context 'game is for another team_size' do
              setup do
                @game.update_column(:team_size, 2)
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_wins
              end
            end

            context 'game is for another game type' do
              setup do
                game_type = FactoryBot.create(:game_type, :with_slack_team_id)
                @game.update_column(:game_type_id, game_type.id)
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_wins
              end
            end
          end

          context 'draw' do
            setup do
              @game = FactoryBot.create(:game, :with_slack_team_id, result: 0.5, player_one_id: @player1.id, player_two_id: @player2.id)
            end

            should 'return 0' do
              assert_equal 0, @player.number_of_wins
            end

            context 'game is for another slack team' do
              setup do
                @game.update_column(:slack_team_id, 'DIFFERENT')
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_wins
              end
            end

            context 'game is for another team_size' do
              setup do
                @game.update_column(:team_size, 2)
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_wins
              end
            end

            context 'game is for another game type' do
              setup do
                game_type = FactoryBot.create(:game_type, :with_slack_team_id)
                @game.update_column(:game_type_id, game_type.id)
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_wins
              end
            end
          end
        end

        context 'as player_two' do
          setup do
            @player1 = @other_player
            @player2 = @player
          end

          context 'win' do
            setup do
              @game = FactoryBot.create(:game, :with_slack_team_id, result: 0, player_one_id: @player1.id, player_two_id: @player2.id)
            end

            should 'return 1' do
              assert_equal 1, @player.number_of_wins
            end

            context 'game is for another slack team' do
              setup do
                @game.update_column(:slack_team_id, 'DIFFERENT')
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_wins
              end
            end

            context 'game is for another team_size' do
              setup do
                @game.update_column(:team_size, 2)
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_wins
              end
            end

            context 'game is for another game type' do
              setup do
                game_type = FactoryBot.create(:game_type, :with_slack_team_id)
                @game.update_column(:game_type_id, game_type.id)
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_wins
              end
            end
          end

          context 'loss' do
            setup do
              @game = FactoryBot.create(:game, :with_slack_team_id, result: 1, player_one_id: @player1.id, player_two_id: @player2.id)
            end

            should 'return 0' do
              assert_equal 0, @player.number_of_wins
            end

            context 'game is for another slack team' do
              setup do
                @game.update_column(:slack_team_id, 'DIFFERENT')
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_wins
              end
            end

            context 'game is for another team_size' do
              setup do
                @game.update_column(:team_size, 2)
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_wins
              end
            end

            context 'game is for another game type' do
              setup do
                game_type = FactoryBot.create(:game_type, :with_slack_team_id)
                @game.update_column(:game_type_id, game_type.id)
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_wins
              end
            end
          end

          context 'draw' do
            setup do
              @game = FactoryBot.create(:game, :with_slack_team_id, result: 0.5, player_one_id: @player1.id, player_two_id: @player2.id)
            end

            should 'return 0' do
              assert_equal 0, @player.number_of_wins
            end

            context 'game is for another slack team' do
              setup do
                @game.update_column(:slack_team_id, 'DIFFERENT')
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_wins
              end
            end

            context 'game is for another team_size' do
              setup do
                @game.update_column(:team_size, 2)
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_wins
              end
            end

            context 'game is for another game type' do
              setup do
                game_type = FactoryBot.create(:game_type, :with_slack_team_id)
                @game.update_column(:game_type_id, game_type.id)
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_wins
              end
            end
          end
        end
      end
    end

    context '#number_of_losses' do
      setup do
        @player = FactoryBot.create(:player1)
        @other_player = FactoryBot.create(:player2)
      end

      context 'with no games' do
        should 'return 0' do
          assert_equal 0, @player.number_of_losses
        end
      end

      context 'with game' do
        context 'as player_one' do
          setup do
            @player1 = @player
            @player2 = @other_player
          end

          context 'win' do
            setup do
              @game = FactoryBot.create(:game, :with_slack_team_id, result: 1, player_one_id: @player1.id, player_two_id: @player2.id)
            end

            should 'return 0' do
              assert_equal 0, @player.number_of_losses
            end

            context 'game is for another slack team' do
              setup do
                @game.update_column(:slack_team_id, 'DIFFERENT')
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_losses
              end
            end

            context 'game is for another team_size' do
              setup do
                @game.update_column(:team_size, 2)
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_losses
              end
            end

            context 'game is for another game type' do
              setup do
                game_type = FactoryBot.create(:game_type, :with_slack_team_id)
                @game.update_column(:game_type_id, game_type.id)
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_losses
              end
            end
          end

          context 'loss' do
            setup do
              @game = FactoryBot.create(:game, :with_slack_team_id, result: 0, player_one_id: @player1.id, player_two_id: @player2.id)
            end

            should 'return 1' do
              assert_equal 1, @player.number_of_losses
            end

            context 'game is for another slack team' do
              setup do
                @game.update_column(:slack_team_id, 'DIFFERENT')
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_losses
              end
            end

            context 'game is for another team_size' do
              setup do
                @game.update_column(:team_size, 2)
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_losses
              end
            end

            context 'game is for another game type' do
              setup do
                game_type = FactoryBot.create(:game_type, :with_slack_team_id)
                @game.update_column(:game_type_id, game_type.id)
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_losses
              end
            end
          end

          context 'draw' do
            setup do
              @game = FactoryBot.create(:game, :with_slack_team_id, result: 0.5, player_one_id: @player1.id, player_two_id: @player2.id)
            end

            should 'return 0' do
              assert_equal 0, @player.number_of_losses
            end

            context 'game is for another slack team' do
              setup do
                @game.update_column(:slack_team_id, 'DIFFERENT')
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_losses
              end
            end

            context 'game is for another team_size' do
              setup do
                @game.update_column(:team_size, 2)
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_losses
              end
            end

            context 'game is for another game type' do
              setup do
                game_type = FactoryBot.create(:game_type, :with_slack_team_id)
                @game.update_column(:game_type_id, game_type.id)
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_losses
              end
            end
          end
        end

        context 'as player_two' do
          setup do
            @player1 = @other_player
            @player2 = @player
          end

          context 'win' do
            setup do
              @game = FactoryBot.create(:game, :with_slack_team_id, result: 0, player_one_id: @player1.id, player_two_id: @player2.id)
            end

            should 'return 0' do
              assert_equal 0, @player.number_of_losses
            end

            context 'game is for another slack team' do
              setup do
                @game.update_column(:slack_team_id, 'DIFFERENT')
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_losses
              end
            end

            context 'game is for another team_size' do
              setup do
                @game.update_column(:team_size, 2)
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_losses
              end
            end

            context 'game is for another game type' do
              setup do
                game_type = FactoryBot.create(:game_type, :with_slack_team_id)
                @game.update_column(:game_type_id, game_type.id)
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_losses
              end
            end
          end

          context 'loss' do
            setup do
              @game = FactoryBot.create(:game, :with_slack_team_id, result: 1, player_one_id: @player1.id, player_two_id: @player2.id)
            end

            should 'return 1' do
              assert_equal 1, @player.number_of_losses
            end

            context 'game is for another slack team' do
              setup do
                @game.update_column(:slack_team_id, 'DIFFERENT')
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_losses
              end
            end

            context 'game is for another team_size' do
              setup do
                @game.update_column(:team_size, 2)
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_losses
              end
            end

            context 'game is for another game type' do
              setup do
                game_type = FactoryBot.create(:game_type, :with_slack_team_id)
                @game.update_column(:game_type_id, game_type.id)
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_losses
              end
            end
          end

          context 'draw' do
            setup do
              @game = FactoryBot.create(:game, :with_slack_team_id, result: 0.5, player_one_id: @player1.id, player_two_id: @player2.id)
            end

            should 'return 0' do
              assert_equal 0, @player.number_of_losses
            end

            context 'game is for another slack team' do
              setup do
                @game.update_column(:slack_team_id, 'DIFFERENT')
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_losses
              end
            end

            context 'game is for another team_size' do
              setup do
                @game.update_column(:team_size, 2)
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_losses
              end
            end

            context 'game is for another game type' do
              setup do
                game_type = FactoryBot.create(:game_type, :with_slack_team_id)
                @game.update_column(:game_type_id, game_type.id)
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_losses
              end
            end
          end
        end
      end
    end

    context '#number_of_ties' do
      setup do
        @player = FactoryBot.create(:player1)
        @other_player = FactoryBot.create(:player2)
      end

      context 'with no games' do
        should 'return 0' do
          assert_equal 0, @player.number_of_ties
        end
      end

      context 'with game' do
        context 'as player_one' do
          setup do
            @player1 = @player
            @player2 = @other_player
          end

          context 'win' do
            setup do
              @game = FactoryBot.create(:game, :with_slack_team_id, result: 1, player_one_id: @player1.id, player_two_id: @player2.id)
            end

            should 'return 0' do
              assert_equal 0, @player.number_of_ties
            end

            context 'game is for another slack team' do
              setup do
                @game.update_column(:slack_team_id, 'DIFFERENT')
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_ties
              end
            end

            context 'game is for another team_size' do
              setup do
                @game.update_column(:team_size, 2)
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_ties
              end
            end

            context 'game is for another game type' do
              setup do
                game_type = FactoryBot.create(:game_type, :with_slack_team_id)
                @game.update_column(:game_type_id, game_type.id)
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_ties
              end
            end
          end

          context 'loss' do
            setup do
              @game = FactoryBot.create(:game, :with_slack_team_id, result: 0, player_one_id: @player1.id, player_two_id: @player2.id)
            end

            should 'return 0' do
              assert_equal 0, @player.number_of_ties
            end

            context 'game is for another slack team' do
              setup do
                @game.update_column(:slack_team_id, 'DIFFERENT')
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_ties
              end
            end

            context 'game is for another team_size' do
              setup do
                @game.update_column(:team_size, 2)
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_ties
              end
            end

            context 'game is for another game type' do
              setup do
                game_type = FactoryBot.create(:game_type, :with_slack_team_id)
                @game.update_column(:game_type_id, game_type.id)
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_ties
              end
            end
          end

          context 'draw' do
            setup do
              @game = FactoryBot.create(:game, :with_slack_team_id, result: 0.5, player_one_id: @player1.id, player_two_id: @player2.id)
            end

            should 'return 1' do
              assert_equal 1, @player.number_of_ties
            end

            context 'game is for another slack team' do
              setup do
                @game.update_column(:slack_team_id, 'DIFFERENT')
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_ties
              end
            end

            context 'game is for another team_size' do
              setup do
                @game.update_column(:team_size, 2)
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_ties
              end
            end

            context 'game is for another game type' do
              setup do
                game_type = FactoryBot.create(:game_type, :with_slack_team_id)
                @game.update_column(:game_type_id, game_type.id)
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_ties
              end
            end
          end
        end

        context 'as player_two' do
          setup do
            @player1 = @other_player
            @player2 = @player
          end

          context 'win' do
            setup do
              @game = FactoryBot.create(:game, :with_slack_team_id, result: 0, player_one_id: @player1.id, player_two_id: @player2.id)
            end

            should 'return 0' do
              assert_equal 0, @player.number_of_ties
            end

            context 'game is for another slack team' do
              setup do
                @game.update_column(:slack_team_id, 'DIFFERENT')
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_ties
              end
            end

            context 'game is for another team_size' do
              setup do
                @game.update_column(:team_size, 2)
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_ties
              end
            end

            context 'game is for another game type' do
              setup do
                game_type = FactoryBot.create(:game_type, :with_slack_team_id)
                @game.update_column(:game_type_id, game_type.id)
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_ties
              end
            end
          end

          context 'loss' do
            setup do
              @game = FactoryBot.create(:game, :with_slack_team_id, result: 1, player_one_id: @player1.id, player_two_id: @player2.id)
            end

            should 'return 0' do
              assert_equal 0, @player.number_of_ties
            end

            context 'game is for another slack team' do
              setup do
                @game.update_column(:slack_team_id, 'DIFFERENT')
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_ties
              end
            end

            context 'game is for another team_size' do
              setup do
                @game.update_column(:team_size, 2)
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_ties
              end
            end

            context 'game is for another game type' do
              setup do
                game_type = FactoryBot.create(:game_type, :with_slack_team_id)
                @game.update_column(:game_type_id, game_type.id)
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_ties
              end
            end
          end

          context 'draw' do
            setup do
              @game = FactoryBot.create(:game, :with_slack_team_id, result: 0.5, player_one_id: @player1.id, player_two_id: @player2.id)
            end

            should 'return 1' do
              assert_equal 1, @player.number_of_ties
            end

            context 'game is for another slack team' do
              setup do
                @game.update_column(:slack_team_id, 'DIFFERENT')
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_ties
              end
            end

            context 'game is for another team_size' do
              setup do
                @game.update_column(:team_size, 2)
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_ties
              end
            end

            context 'game is for another game type' do
              setup do
                game_type = FactoryBot.create(:game_type, :with_slack_team_id)
                @game.update_column(:game_type_id, game_type.id)
              end

              should 'return 0' do
                assert_equal 0, @player.number_of_ties
              end
            end
          end
        end
      end
    end

    context '#nemesis' do
      [1, 2].each do |team_size|
        context "team_size:#{team_size}" do
          setup do
            @player = team_size == 1 ? FactoryBot.create(:player1) : FactoryBot.create(:doubles_player1)
            @player2 = team_size == 1 ? FactoryBot.create(:player2) : FactoryBot.create(:doubles_player2)
            @player3 = team_size == 1 ? FactoryBot.create(:player3) : FactoryBot.create(:doubles_player3)
          end

          [1, 2].each do |player_num_v_p2|
            context "as player #{player_num_v_p2}" do
              setup do
                players = [@player, @player2]
                players.reverse! if player_num_v_p2 == 2
                @player1_v_p2, @player2_v_p2 = players
              end

              [0, 2, 4, 5].repeated_permutation(2).each do |wins_v_p2, losses_v_p2|
                context "#{wins_v_p2}-#{losses_v_p2} v p2" do
                  setup do
                    wins_v_p2.times { FactoryBot.create(:game, :with_slack_team_id, player_one_id: @player1_v_p2.id, player_two_id: @player2_v_p2.id, result: player_num_v_p2 == 1 ? 1 : 0) }
                    losses_v_p2.times { FactoryBot.create(:game, :with_slack_team_id, player_one_id: @player1_v_p2.id, player_two_id: @player2_v_p2.id, result: player_num_v_p2 == 1 ? 0 : 1) }
                  end

                  [1, 2].each do |player_num_v_p3|
                    context "as player #{player_num_v_p3}" do
                      setup do
                        players = [@player, @player3]
                        players.reverse! if player_num_v_p3 == 2
                        @player1_v_p3, @player2_v_p3 = players
                      end

                      [0, 1, 3, 5].repeated_permutation(2).each do |wins_v_p3, losses_v_p3|
                        context "#{wins_v_p3}-#{losses_v_p3} v p3" do
                          setup do
                            wins_v_p3.times { FactoryBot.create(:game, :with_slack_team_id, player_one_id: @player1_v_p3.id, player_two_id: @player2_v_p3.id, result: player_num_v_p3 == 1 ? 1 : 0) }
                            losses_v_p3.times { FactoryBot.create(:game, :with_slack_team_id, player_one_id: @player1_v_p3.id, player_two_id: @player2_v_p3.id, result: player_num_v_p3 == 1 ? 0 : 1) }
                          end

                          p2_nemesis = wins_v_p2 + losses_v_p2 > 3 && wins_v_p2 < losses_v_p2
                          p3_nemesis = wins_v_p3 + losses_v_p3 > 3 && wins_v_p3 < losses_v_p3
                          if p2_nemesis && p3_nemesis
                            p2_win_ratio = (wins_v_p2.to_f + 1) / (wins_v_p2 + losses_v_p2)
                            p3_win_ratio = (wins_v_p3.to_f + 1) / (wins_v_p3 + losses_v_p3)
                            if p3_win_ratio < p2_win_ratio
                              should 'return p3 as nemesis' do
                                assert_equal @player3.team_tag, @player.nemesis
                              end
                            else
                              should 'return p2 as nemesis' do
                                assert_equal @player2.team_tag, @player.nemesis
                              end
                            end
                          elsif p2_nemesis
                            should 'return p2 as nemesis' do
                              assert_equal @player2.team_tag, @player.nemesis
                            end
                          elsif p3_nemesis
                            should 'return p3 as nemesis' do
                              assert_equal @player3.team_tag, @player.nemesis
                            end
                          else
                            should 'not return a nemesis' do
                              assert_nil @player.nemesis
                            end
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
          end

          context '4 losses against P2, 5 losses against P3' do
            setup do
              4.times { FactoryBot.create(:game, :with_slack_team_id, :player_one_loses, player_one: @player, player_two: @player2) }
              5.times { FactoryBot.create(:game, :with_slack_team_id, :player_one_loses, player_one: @player, player_two: @player3) }
            end

            should 'return P3 as nemesis' do
              assert_equal @player3.team_tag, @player.nemesis
            end
          end
        end
      end

      context 'doubles_individual' do
        setup do
          @p1_slack_user_id = '@PLAYER1'
          @p2_slack_user_id = '@PLAYER2'
          @p3_slack_user_id = '@PLAYER3'
          @p4_slack_user_id = '@PLAYER4'

          @p1p2 = FactoryBot.create(:player, :with_slack_team_id, :with_game_type, :doubles, slack_user_id: "#{@p1_slack_user_id}-#{@p2_slack_user_id}")
          @p1p3 = FactoryBot.create(:player, :with_slack_team_id, :with_game_type, :doubles, slack_user_id: "#{@p1_slack_user_id}-#{@p3_slack_user_id}")
          @p1p4 = FactoryBot.create(:player, :with_slack_team_id, :with_game_type, :doubles, slack_user_id: "#{@p1_slack_user_id}-#{@p4_slack_user_id}")
          @p2p3 = FactoryBot.create(:player, :with_slack_team_id, :with_game_type, :doubles, slack_user_id: "#{@p2_slack_user_id}-#{@p3_slack_user_id}")
          @p2p4 = FactoryBot.create(:player, :with_slack_team_id, :with_game_type, :doubles, slack_user_id: "#{@p2_slack_user_id}-#{@p4_slack_user_id}")
          @p3p4 = FactoryBot.create(:player, :with_slack_team_id, :with_game_type, :doubles, slack_user_id: "#{@p3_slack_user_id}-#{@p4_slack_user_id}")

          @player = Player.new(slack_team_id: 'SLACKTEAMID', slack_user_id: @p1_slack_user_id, game_type_id: @p1p2.game_type_id, team_size: 2)
        end

        should 'return no nemesis' do
          assert_nil @player.nemesis
        end

        context '1 loss against P2' do
          context 'on T1' do
            setup do
              FactoryBot.create(:game, :with_slack_team_id, :player_one_loses, player_one: @p1p3, player_two: @p2p4)
            end

            should 'return no nemesis' do
              assert_nil @player.nemesis
            end
          end

          context 'on T2' do
            setup do
              FactoryBot.create(:game, :with_slack_team_id, :player_one_wins, player_one: @p2p4, player_two: @p1p3)
            end

            should 'return no nemesis' do
              assert_nil @player.nemesis
            end
          end
        end

        context '4 losses against P2' do
          context 'on T1' do
            setup do
              4.times do |i|
                team1, team2 = i.even? ? [@p1p3, @p2p4] : [@p1p4, @p2p3]
                FactoryBot.create(:game, :with_slack_team_id, :player_one_loses, player_one: team1, player_two: team2)
              end
            end

            should 'return P2 as nemesis' do
              assert_equal "<#{@p2_slack_user_id}>", @player.nemesis
            end
          end

          context 'on T2' do
            setup do
              4.times do |i|
                team1, team2 = i.even? ? [@p1p4, @p2p3] : [@p1p3, @p2p4]
                FactoryBot.create(:game, :with_slack_team_id, :player_one_loses, player_one: team1, player_two: team2)
              end
            end

            should 'return P2 as nemesis' do
              assert_equal "<#{@p2_slack_user_id}>", @player.nemesis
            end
          end
        end
        
        context '5 losses against P2, 5 losses against P3, 6 losses against P4' do
          setup do
            FactoryBot.create(:game, :with_slack_team_id, :player_one_loses, player_one: @p1p2, player_two: @p3p4)
            FactoryBot.create(:game, :with_slack_team_id, :player_one_loses, player_one: @p1p2, player_two: @p3p4)
            FactoryBot.create(:game, :with_slack_team_id, :player_one_loses, player_one: @p1p2, player_two: @p3p4)
            FactoryBot.create(:game, :with_slack_team_id, :player_one_loses, player_one: @p1p3, player_two: @p2p4)
            FactoryBot.create(:game, :with_slack_team_id, :player_one_loses, player_one: @p1p3, player_two: @p2p4)
            FactoryBot.create(:game, :with_slack_team_id, :player_one_loses, player_one: @p1p3, player_two: @p2p4)
            FactoryBot.create(:game, :with_slack_team_id, :player_one_loses, player_one: @p1p4, player_two: @p2p3)
            FactoryBot.create(:game, :with_slack_team_id, :player_one_loses, player_one: @p1p4, player_two: @p2p3)
          end

          should 'return P4 as nemesis' do
            assert_equal "<#{@p4_slack_user_id}>", @player.nemesis
          end
        end

        context '2-3 against P2, 4-3 against P3, 6-6 against P4' do
          setup do
            FactoryBot.create(:game, :with_slack_team_id, :player_one_loses, player_one: @p1p3, player_two: @p2p4)
            FactoryBot.create(:game, :with_slack_team_id, :player_one_loses, player_one: @p1p3, player_two: @p2p4)
            FactoryBot.create(:game, :with_slack_team_id, :player_one_loses, player_one: @p1p3, player_two: @p2p4)
            FactoryBot.create(:game, :with_slack_team_id, :player_one_wins, player_one: @p1p3, player_two: @p2p4)
            FactoryBot.create(:game, :with_slack_team_id, :player_one_wins, player_one: @p1p3, player_two: @p2p4)

            FactoryBot.create(:game, :with_slack_team_id, :player_one_loses, player_one: @p1p2, player_two: @p3p4)
            FactoryBot.create(:game, :with_slack_team_id, :player_one_loses, player_one: @p1p2, player_two: @p3p4)
            FactoryBot.create(:game, :with_slack_team_id, :player_one_loses, player_one: @p1p2, player_two: @p3p4)
            FactoryBot.create(:game, :with_slack_team_id, :player_one_wins, player_one: @p1p2, player_two: @p3p4)
            FactoryBot.create(:game, :with_slack_team_id, :player_one_wins, player_one: @p1p2, player_two: @p3p4)
            FactoryBot.create(:game, :with_slack_team_id, :player_one_wins, player_one: @p1p2, player_two: @p3p4)
            FactoryBot.create(:game, :with_slack_team_id, :player_one_wins, player_one: @p1p2, player_two: @p3p4)
          end

          should 'return P2 as nemesis' do
            assert_equal "<#{@p2_slack_user_id}>", @player.nemesis
          end
        end
      end
    end

    context '#log_game' do
      setup do
        @player1 = FactoryBot.create(:player1)
        @player2 = FactoryBot.create(:player2)
        @logger = 'LOGGER'
        @result = 1
      end

      should 'create Game' do
        game = nil
        assert_difference('Game.count') do
          game = @player1.log_game(@player2, @logger, @result)
        end
        assert_not_nil game
        expected = {
            id: :present,
            logged_by_slack_user_id: @logger,
            player_one_id: @player1.id,
            player_two_id: @player2.id,
            result: @result,
            created_at: :present,
            updated_at: :present,
            slack_team_id: @player1.slack_team_id,
            player_one_slack_user_id: @player1.slack_user_id,
            player_two_slack_user_id: @player2.slack_user_id,
            game_type_id: @player1.game_type_id,
            team_size: @player1.team_size
        }
        assert_equivalent(expected, game.attributes.with_indifferent_access)
      end

      should 'update P1 rating' do
        rating_before = @player1.rating
        @player1.log_game(@player2, @logger, @result)
        rating_after = @player1.rating
        assert_not_equal rating_before, rating_after
        rating_after = @player1.reload.rating
        assert_not_equal rating_before, rating_after
      end

      should 'update P2 rating' do
        rating_before = @player2.rating
        @player1.log_game(@player2, @logger, @result)
        rating_after = @player2.rating
        assert_not_equal rating_before, rating_after
        rating_after = @player2.reload.rating
        assert_not_equal rating_before, rating_after
      end

      context 'P2 is for another game_type' do
        setup do
          game_type = FactoryBot.create(:game_type, :with_slack_team_id)
          @player2.update_column(:game_type_id, game_type.id)
        end

        should 'raise ArgumentError' do
          e = assert_raises(ArgumentError) do
            @player1.log_game(@player2, @logger, @result)
          end
          assert_equal 'other_player is for different game_type', e.message
        end
      end

      context 'P2 is for another team_size' do
        setup do
          @player2 = FactoryBot.create(:doubles_player2)
        end

        should 'raise ArgumentError' do
          e = assert_raises(ArgumentError) do
            @player1.log_game(@player2, @logger, @result)
          end
          assert_equal 'other_player is for different team_size', e.message
        end
      end

      context 'P2 is for another slack_team' do
        setup do
          @player2.update_column(:slack_team_id, 'DIFFERENT')
        end

        should 'raise ArgumentError' do
          e = assert_raises(ArgumentError) do
            @player1.log_game(@player2, @logger, @result)
          end
          assert_equal 'other_player is for different slack_team', e.message
        end
      end
    end
  end
end
