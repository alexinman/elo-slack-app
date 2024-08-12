require 'test_helper'

class EloControllerTest < ActionController::TestCase
  context 'EloControllerTest' do
    setup do
      @params = {
          team_id: 'SLACKTEAMID',
          user_id: 'CURRENTUSER',
          text: ''
      }
      Timecop.freeze
    end

    teardown do
      Timecop.return
    end

    context '#elo' do
      context 'w/ slack signature' do
        context 'missing team_id' do
          setup do
            @params.delete(:team_id)
          end

          should 'return bad_request' do
            post_elo
            assert_response :bad_request
          end
        end

        context 'missing user_id' do
          setup do
            @params.delete(:user_id)
          end

          should 'return bad_request' do
            post_elo
            assert_response :bad_request
          end
        end

        context 'missing text' do
          setup do
            @params.delete(:text)
          end

          should 'return bad_request' do
            post_elo
            assert_response :bad_request
          end
        end

        context 'valid request' do
          context 'no text' do
            should 'return help message' do
              post_elo
              assert_help_message
            end
          end

          context 'help' do
            setup do
              @params[:text] = 'help'
            end

            should 'return help message' do
              post_elo
              assert_help_message
            end
          end

          context 'leaderboard' do
            context 'invalid game name' do
              setup do
                @params[:text] = 'leaderboard foobar'
              end

              should 'return invalid game name message' do
                post_elo
                assert_simple_response "Sorry! :sweat_smile: We couldn't determine what game you're referring to. Please make sure the game you're referring to is registered (`/elo games`) and if it isn't, please register it (`/elo register [game]`)."
              end
            end

            context 'valid game name' do
              setup do
                @game_type = FactoryBot.create(:game_type)
                @params[:text] = "leaderboard #{@game_type.game_name}"
              end

              context 'w/o players' do
                should 'return no players message' do
                  post_elo
                  assert_simple_response "No one has played any ELO rated games of #{@game_type.game_name} yet."
                end
              end

              context 'w/ players' do
                setup do
                  @player = FactoryBot.create(:player1, game_type: @game_type)
                end

                should 'return leaderboard' do
                  post_elo
                  leaderboard = [
                      {
                          "text" => "1. #{@player.team_tag} (#{@player.rating})",
                          "footer_icon" => "#{AppConfig[:root_url]}/images/baseline_person_black_18dp.png",
                          "footer" => "Singles",
                          "ts" => Time.now.to_i
                      }
                  ]
                  expected = expected_response(text: "Here is the current leaderboard for #{@game_type.game_name}:", attachments: leaderboard)
                  assert_json_response expected
                end
              end
            end
          end

          context 'stats' do
            setup do
              @game_type = FactoryBot.create(:game_type)
            end

            context 'w/ results' do
              setup do
                @player = FactoryBot.create(:player1, game_type: @game_type)
                @params[:text] = "stats #{@game_type.game_name} #{@player.team_tag}"
              end

              should 'return stats' do
                post_elo
                stat = {
                    "title" => @player.team_tag,
                    "fallback" => "Elo rating: #{@player.rating}",
                    "fields" => [
                        {
                            "title" => "Rank",
                            "value" => "1. #{@player.team_tag} (#{@player.rating})",
                            "short" => false
                        },
                        {
                            "title" => "Wins",
                            "value" => 0,
                            "short" => true
                        },
                        {
                            "title" => "Losses",
                            "value" => 0,
                            "short" => true
                        },
                        {
                            "title" => "Recent Games",
                            "value" => "",
                            "short" => false
                        }
                    ],
                    "footer" => @game_type.game_name.titleize,
                    "footer_icon" => "#{AppConfig[:root_url]}/images/baseline_person_black_18dp.png",
                    "ts" => Time.now.to_i
                }
                expected = expected_response(attachments: [stat])
                assert_json_response expected, allow_nil: true
              end
            end

            context 'w/o results' do
              context 'current user stats' do
                context 'singles' do
                  context 'w/ specified game' do
                    setup do
                      @params[:text] = "stats #{@game_type.game_name}"
                    end

                    should 'return no games message' do
                      post_elo
                      assert_simple_response "You haven't played any ELO rated games of #{@game_type.game_name} yet."
                    end
                  end

                  context 'w/o specified game' do
                    setup do
                      @params[:text] = 'stats'
                    end

                    should 'return no games message' do
                      post_elo
                      assert_simple_response "You haven't played any ELO rated games yet."
                    end
                  end
                end

                context 'doubles' do
                  context 'w/ specified game' do
                    setup do
                      @params[:text] = "stats <@CURRENTUSER> and <@PLAYER1> #{@game_type.game_name}"
                    end

                    should 'return no games message' do
                      post_elo
                      assert_simple_response "You and <@PLAYER1> haven't played any ELO rated games of #{@game_type.game_name} yet."
                    end
                  end

                  context 'w/o specified game' do
                    setup do
                      @params[:text] = "stats <@CURRENTUSER> and <@PLAYER1>"
                    end

                    should 'return no games message' do
                      post_elo
                      assert_simple_response "You and <@PLAYER1> haven't played any ELO rated games yet."
                    end
                  end
                end
              end

              context 'other player stats' do
                context 'singles' do
                  context 'w/ specified game' do
                    setup do
                      @params[:text] = "stats <@PLAYER1> #{@game_type.game_name}"
                    end

                    should 'return no games message' do
                      post_elo
                      assert_simple_response "<@PLAYER1> hasn't played any ELO rated games of #{@game_type.game_name} yet."
                    end
                  end

                  context 'w/o specified game' do
                    setup do
                      @params[:text] = "stats <@PLAYER1>"
                    end

                    should 'return no games message' do
                      post_elo
                      assert_simple_response "<@PLAYER1> hasn't played any ELO rated games yet."
                    end
                  end
                end

                context 'doubles' do
                  context 'w/ specified game' do
                    setup do
                      @params[:text] = "stats <@PLAYER1> and <@PLAYER2> #{@game_type.game_name}"
                    end

                    should 'return no games message' do
                      post_elo
                      assert_simple_response "<@PLAYER2> and <@PLAYER1> haven't played any ELO rated games of #{@game_type.game_name} yet."
                    end
                  end

                  context 'w/o specified game' do
                    setup do
                      @params[:text] = "stats <@PLAYER1> and <@PLAYER2>"
                    end

                    should 'return no games message' do
                      post_elo
                      assert_simple_response "<@PLAYER2> and <@PLAYER1> haven't played any ELO rated games yet."
                    end
                  end
                end
              end
            end
          end

          context 'register' do
            context 'w/ game name provided' do
              context 'w/ existing game' do
                setup do
                  @game_type = FactoryBot.create(:game_type)
                  @params[:text] = "register #{@game_type.game_name}"
                end

                should 'return already registered message' do
                  post_elo
                  assert_simple_response 'That game has already been registered.'
                end
              end

              context 'w/o existing game' do
                setup do
                  @params[:text] = 'register pingpong'
                end

                should 'return success message' do
                  post_elo
                  assert_simple_response 'Successfully registered pingpong as a game for this team!'
                end

                should 'create GameType for team' do
                  assert_difference('GameType.count') do
                    post_elo
                    assert_predicate GameType.where(slack_team_id: 'SLACKTEAMID', game_name: 'pingpong'), :exists?
                  end
                end
              end
            end

            context 'w/o game name provided' do
              setup do
                @params[:text] = 'register'
              end

              should 'return requirement message' do
                post_elo
                assert_simple_response "You must provide the name of the game you'd like to register. (Private Groups and Direct Messages cannot be used as game names.)"
              end
            end
          end

          context 'games' do
            setup do
              @params[:text] = 'games'
            end

            context 'w/ games' do
              setup do
                @game_type = FactoryBot.create(:game_type)
              end

              should 'return list of games' do
                post_elo
                assert_simple_response "Here are all the registered types of games for this team:\n• #{@game_type.game_name}"
              end
            end

            context 'w/o games' do
              should 'return no games message' do
                post_elo
                assert_simple_response "No types of games have been registered for this team yet. Try `/elo register [game]`."
              end
            end
          end

          context 'log a game' do
            setup do
              @game_type = FactoryBot.create(:game_type)
              @params[:channel_name] = @game_type.game_name
            end

            context 'valid' do
              context 'singles' do
                context 'player1 exists' do
                  setup do
                    @player1 = FactoryBot.create(:player1, game_type: @game_type, rating: 1100)
                  end

                  context 'player2 exists' do
                    setup do
                      @player2 = FactoryBot.create(:player2, game_type: @game_type, rating: 1200)
                    end

                    context 'player1 wins' do
                      setup do
                        @params[:text] = '<@PLAYER1> beat <@PLAYER2>'
                      end

                      should 'log game' do
                        assert_difference('Game.count') do
                          post_elo
                          assert_predicate Game.where(player_one_id: @player1.id, player_two_id: @player2.id, result: 1), :exists?
                        end
                      end

                      should 'return congratulations message' do
                        post_elo
                        expected = /Congratulations to #{@player1.team_tag} \(\+\d+\) :.*: on defeating #{@player2.team_tag} \(-\d+\) :.*: at #{@game_type.game_name}!/
                        assert_json_response({'text' => expected})
                      end

                      should 'return response type in channel' do
                        post_elo
                        assert_json_response({'response_type' => 'in_channel'})
                      end

                      should 'not create new players' do
                        assert_no_difference('Player.count', &method(:post_elo))
                      end

                      should 'update player ratings' do
                        post_elo
                        assert_not_equal @player1.rating, @player1.reload.rating
                        assert_not_equal @player2.rating, @player2.reload.rating
                      end
                    end

                    context 'player1 loses' do
                      setup do
                        @params[:text] = '<@PLAYER1> lost to <@PLAYER2>'
                      end

                      should 'log game' do
                        assert_difference('Game.count') do
                          post_elo
                          assert_predicate Game.where(player_one_id: @player1.id, player_two_id: @player2.id, result: 0), :exists?
                        end
                      end

                      should 'return congratulations message' do
                        post_elo
                        expected = /Congratulations to #{@player2.team_tag} \(\+\d+\) :.*: on defeating #{@player1.team_tag} \(-\d+\) :.*: at #{@game_type.game_name}!/
                        assert_json_response({'text' => expected})
                      end

                      should 'return response type in channel' do
                        post_elo
                        assert_json_response({'response_type' => 'in_channel'})
                      end

                      should 'not create new players' do
                        assert_no_difference('Player.count', &method(:post_elo))
                      end

                      should 'update player ratings' do
                        post_elo
                        assert_not_equal @player1.rating, @player1.reload.rating
                        assert_not_equal @player2.rating, @player2.reload.rating
                      end
                    end

                    context 'draw' do
                      setup do
                        @params[:text] = '<@PLAYER1> tied <@PLAYER2>'
                      end

                      should 'log game' do
                        assert_difference('Game.count') do
                          post_elo
                          assert_predicate Game.where(player_one_id: @player1.id, player_two_id: @player2.id, result: 0.5), :exists?
                        end
                      end

                      should 'return congratulations message' do
                        post_elo
                        expected = /#{@player1.team_tag} \((\+|-)\d+\) :.*: tied #{@player2.team_tag} \((\+|-)\d+\) :.*: at #{@game_type.game_name}\./
                        assert_json_response({'text' => expected})
                      end

                      should 'return response type in channel' do
                        post_elo
                        assert_json_response({'response_type' => 'in_channel'})
                      end

                      should 'not create new players' do
                        assert_no_difference('Player.count', &method(:post_elo))
                      end

                      should 'update player ratings' do
                        post_elo
                        assert_not_equal @player1.rating, @player1.reload.rating
                        assert_not_equal @player2.rating, @player2.reload.rating
                      end
                    end
                  end

                  context 'player2 does not exist' do
                    context 'player1 wins' do
                      setup do
                        @params[:text] = '<@PLAYER1> beat <@PLAYER2>'
                      end

                      should 'log game' do
                        assert_difference('Game.count') do
                          post_elo
                          assert_predicate Game.where(player_one_id: @player1.id, result: 1), :exists?
                        end
                      end

                      should 'return congratulations message' do
                        post_elo
                        expected = /Congratulations to #{@player1.team_tag} \(\+\d+\) :.*: on defeating <@PLAYER2> \(-\d+\) :.*: at #{@game_type.game_name}!/
                        assert_json_response({'text' => expected})
                      end

                      should 'return response type in channel' do
                        post_elo
                        assert_json_response({'response_type' => 'in_channel'})
                      end

                      should 'not create new players' do
                        assert_difference('Player.count', &method(:post_elo))
                      end

                      should 'update player ratings' do
                        post_elo
                        assert_not_equal @player1.rating, @player1.reload.rating
                        player2 = Player.where(slack_user_id: '@PLAYER2').take
                        assert_not_nil player2
                        assert_not_equal 1000, player2.rating
                      end
                    end

                    context 'player1 loses' do
                      setup do
                        @params[:text] = '<@PLAYER1> lost to <@PLAYER2>'
                      end

                      should 'log game' do
                        assert_difference('Game.count') do
                          post_elo
                          assert_predicate Game.where(player_one_id: @player1.id, result: 0), :exists?
                        end
                      end

                      should 'return congratulations message' do
                        post_elo
                        expected = /Congratulations to <@PLAYER2> \(\+\d+\) :.*: on defeating #{@player1.team_tag} \(-\d+\) :.*: at #{@game_type.game_name}!/
                        assert_json_response({'text' => expected})
                      end

                      should 'return response type in channel' do
                        post_elo
                        assert_json_response({'response_type' => 'in_channel'})
                      end

                      should 'not create new players' do
                        assert_difference('Player.count', &method(:post_elo))
                      end

                      should 'update player ratings' do
                        post_elo
                        assert_not_equal @player1.rating, @player1.reload.rating
                        player2 = Player.where(slack_user_id: '@PLAYER2').take
                        assert_not_nil player2
                        assert_not_equal 1000, player2.rating
                      end
                    end

                    context 'draw' do
                      setup do
                        @params[:text] = '<@PLAYER1> tied <@PLAYER2>'
                      end

                      should 'log game' do
                        assert_difference('Game.count') do
                          post_elo
                          assert_predicate Game.where(player_one_id: @player1.id, result: 0.5), :exists?
                        end
                      end

                      should 'return congratulations message' do
                        post_elo
                        expected = /#{@player1.team_tag} \((\+|-)\d+\) :.*: tied <@PLAYER2> \((\+|-)\d+\) :.*: at #{@game_type.game_name}\./
                        assert_json_response({'text' => expected})
                      end

                      should 'return response type in channel' do
                        post_elo
                        assert_json_response({'response_type' => 'in_channel'})
                      end

                      should 'not create new players' do
                        assert_difference('Player.count', &method(:post_elo))
                      end

                      should 'update player ratings' do
                        post_elo
                        assert_not_equal @player1.rating, @player1.reload.rating
                        player2 = Player.where(slack_user_id: '@PLAYER2').take
                        assert_not_nil player2
                        assert_not_equal 1000, player2.rating
                      end
                    end
                  end
                end

                context 'player1 does not exist' do
                  context 'player2 exists' do
                    setup do
                      @player2 = FactoryBot.create(:player2, game_type: @game_type, rating: 1200)
                    end

                    context 'player1 wins' do
                      setup do
                        @params[:text] = '<@PLAYER1> beat <@PLAYER2>'
                      end

                      should 'log game' do
                        assert_difference('Game.count') do
                          post_elo
                          assert_predicate Game.where(player_two_id: @player2.id, result: 1), :exists?
                        end
                      end

                      should 'return congratulations message' do
                        post_elo
                        expected = /Congratulations to <@PLAYER1> \(\+\d+\) :.*: on defeating #{@player2.team_tag} \(-\d+\) :.*: at #{@game_type.game_name}!/
                        assert_json_response({'text' => expected})
                      end

                      should 'return response type in channel' do
                        post_elo
                        assert_json_response({'response_type' => 'in_channel'})
                      end

                      should 'not create new players' do
                        assert_difference('Player.count', &method(:post_elo))
                      end

                      should 'update player ratings' do
                        post_elo
                        player1 = Player.where(slack_user_id: '@PLAYER1').take
                        assert_not_nil player1
                        assert_not_equal 1000, player1.rating
                        assert_not_equal @player2.rating, @player2.reload.rating
                      end
                    end

                    context 'player1 loses' do
                      setup do
                        @params[:text] = '<@PLAYER1> lost to <@PLAYER2>'
                      end

                      should 'log game' do
                        assert_difference('Game.count') do
                          post_elo
                          assert_predicate Game.where(player_two_id: @player2.id, result: 0), :exists?
                        end
                      end

                      should 'return congratulations message' do
                        post_elo
                        expected = /Congratulations to #{@player2.team_tag} \(\+\d+\) :.*: on defeating <@PLAYER1> \(-\d+\) :.*: at #{@game_type.game_name}!/
                        assert_json_response({'text' => expected})
                      end

                      should 'return response type in channel' do
                        post_elo
                        assert_json_response({'response_type' => 'in_channel'})
                      end

                      should 'not create new players' do
                        assert_difference('Player.count', &method(:post_elo))
                      end

                      should 'update player ratings' do
                        post_elo
                        player1 = Player.where(slack_user_id: '@PLAYER1').take
                        assert_not_nil player1
                        assert_not_equal 1000, player1.rating
                        assert_not_equal @player2.rating, @player2.reload.rating
                      end
                    end

                    context 'draw' do
                      setup do
                        @params[:text] = '<@PLAYER1> tied <@PLAYER2>'
                      end

                      should 'log game' do
                        assert_difference('Game.count') do
                          post_elo
                          assert_predicate Game.where(player_two_id: @player2.id, result: 0.5), :exists?
                        end
                      end

                      should 'return congratulations message' do
                        post_elo
                        expected = /<@PLAYER1> \((\+|-)\d+\) :.*: tied #{@player2.team_tag} \((\+|-)\d+\) :.*: at #{@game_type.game_name}\./
                        assert_json_response({'text' => expected})
                      end

                      should 'return response type in channel' do
                        post_elo
                        assert_json_response({'response_type' => 'in_channel'})
                      end

                      should 'not create new players' do
                        assert_difference('Player.count', &method(:post_elo))
                      end

                      should 'update player ratings' do
                        post_elo
                        player1 = Player.where(slack_user_id: '@PLAYER1').take
                        assert_not_nil player1
                        assert_not_equal 1000, player1.rating
                        assert_not_equal @player2.rating, @player2.reload.rating
                      end
                    end
                  end

                  context 'player2 does not exist' do
                    context 'player1 wins' do
                      setup do
                        @params[:text] = '<@PLAYER1> beat <@PLAYER2>'
                      end

                      should 'log game' do
                        assert_difference('Game.count') do
                          post_elo
                          assert_predicate Game.where(slack_team_id: 'SLACKTEAMID', result: 1), :exists?
                        end
                      end

                      should 'return congratulations message' do
                        post_elo
                        expected = /Congratulations to <@PLAYER1> \(\+\d+\) :.*: on defeating <@PLAYER2> \(-\d+\) :.*: at #{@game_type.game_name}!/
                        assert_json_response({'text' => expected})
                      end

                      should 'return response type in channel' do
                        post_elo
                        assert_json_response({'response_type' => 'in_channel'})
                      end

                      should 'not create new players' do
                        assert_difference('Player.count', 2, &method(:post_elo))
                      end

                      should 'update player ratings' do
                        post_elo
                        player1 = Player.where(slack_user_id: '@PLAYER1').take
                        assert_not_nil player1
                        assert_not_equal 1000, player1.rating
                        player2 = Player.where(slack_user_id: '@PLAYER2').take
                        assert_not_nil player2
                        assert_not_equal 1000, player2.rating
                      end
                    end

                    context 'player1 loses' do
                      setup do
                        @params[:text] = '<@PLAYER1> lost to <@PLAYER2>'
                      end

                      should 'log game' do
                        assert_difference('Game.count') do
                          post_elo
                          assert_predicate Game.where(slack_team_id: 'SLACKTEAMID', result: 0), :exists?
                        end
                      end

                      should 'return congratulations message' do
                        post_elo
                        expected = /Congratulations to <@PLAYER2> \(\+\d+\) :.*: on defeating <@PLAYER1> \(-\d+\) :.*: at #{@game_type.game_name}!/
                        assert_json_response({'text' => expected})
                      end

                      should 'return response type in channel' do
                        post_elo
                        assert_json_response({'response_type' => 'in_channel'})
                      end

                      should 'not create new players' do
                        assert_difference('Player.count', 2, &method(:post_elo))
                      end

                      should 'update player ratings' do
                        post_elo
                        player1 = Player.where(slack_user_id: '@PLAYER1').take
                        assert_not_nil player1
                        assert_not_equal 1000, player1.rating
                        player2 = Player.where(slack_user_id: '@PLAYER2').take
                        assert_not_nil player2
                        assert_not_equal 1000, player2.rating
                      end
                    end

                    context 'draw' do
                      setup do
                        @params[:text] = '<@PLAYER1> tied <@PLAYER2>'
                      end

                      should 'log game' do
                        assert_difference('Game.count') do
                          post_elo
                          assert_predicate Game.where(slack_team_id: 'SLACKTEAMID', result: 0.5), :exists?
                        end
                      end

                      should 'return congratulations message' do
                        post_elo
                        expected = /<@PLAYER1> \((\+|-)\d+\) :.*: tied <@PLAYER2> \((\+|-)\d+\) :.*: at #{@game_type.game_name}\./
                        assert_json_response({'text' => expected})
                      end

                      should 'return response type in channel' do
                        post_elo
                        assert_json_response({'response_type' => 'in_channel'})
                      end

                      should 'not create new players' do
                        assert_difference('Player.count', 2, &method(:post_elo))
                      end
                    end
                  end
                end
              end

              context 'doubles' do
                context 'player1 exists' do
                  setup do
                    @player1 = FactoryBot.create(:doubles_player1, game_type: @game_type, rating: 1100)
                  end

                  context 'player2 exists' do
                    setup do
                      @player2 = FactoryBot.create(:doubles_player2, game_type: @game_type, rating: 1200)
                    end

                    context 'player1 wins' do
                      setup do
                        @params[:text] = '<@PLAYER1> and <@PLAYER2> beat <@PLAYER3> and <@PLAYER4>'
                      end

                      should 'log game' do
                        assert_difference('Game.count') do
                          post_elo
                          assert_predicate Game.where(player_one_id: @player1.id, player_two_id: @player2.id, result: 1), :exists?
                        end
                      end

                      should 'return congratulations message' do
                        post_elo
                        expected = /Congratulations to #{@player1.team_tag} \(\+\d+\) :.*: on defeating #{@player2.team_tag} \(-\d+\) :.*: at #{@game_type.game_name}!/
                        assert_json_response({'text' => expected})
                      end

                      should 'return response type in channel' do
                        post_elo
                        assert_json_response({'response_type' => 'in_channel'})
                      end

                      should 'not create new players' do
                        assert_no_difference('Player.count', &method(:post_elo))
                      end

                      should 'update player ratings' do
                        post_elo
                        assert_not_equal @player1.rating, @player1.reload.rating
                        assert_not_equal @player2.rating, @player2.reload.rating
                      end
                    end

                    context 'player1 loses' do
                      setup do
                        @params[:text] = '<@PLAYER1> and <@PLAYER2> lost to <@PLAYER3> and <@PLAYER4>'
                      end

                      should 'log game' do
                        assert_difference('Game.count') do
                          post_elo
                          assert_predicate Game.where(player_one_id: @player1.id, player_two_id: @player2.id, result: 0), :exists?
                        end
                      end

                      should 'return congratulations message' do
                        post_elo
                        expected = /Congratulations to #{@player2.team_tag} \(\+\d+\) :.*: on defeating #{@player1.team_tag} \(-\d+\) :.*: at #{@game_type.game_name}!/
                        assert_json_response({'text' => expected})
                      end

                      should 'return response type in channel' do
                        post_elo
                        assert_json_response({'response_type' => 'in_channel'})
                      end

                      should 'not create new players' do
                        assert_no_difference('Player.count', &method(:post_elo))
                      end

                      should 'update player ratings' do
                        post_elo
                        assert_not_equal @player1.rating, @player1.reload.rating
                        assert_not_equal @player2.rating, @player2.reload.rating
                      end
                    end

                    context 'draw' do
                      setup do
                        @params[:text] = '<@PLAYER1> and <@PLAYER2> tied <@PLAYER3> and <@PLAYER4>'
                      end

                      should 'log game' do
                        assert_difference('Game.count') do
                          post_elo
                          assert_predicate Game.where(player_one_id: @player1.id, player_two_id: @player2.id, result: 0.5), :exists?
                        end
                      end

                      should 'return congratulations message' do
                        post_elo
                        expected = /#{@player1.team_tag} \((\+|-)\d+\) :.*: tied #{@player2.team_tag} \((\+|-)\d+\) :.*: at #{@game_type.game_name}\./
                        assert_json_response({'text' => expected})
                      end

                      should 'return response type in channel' do
                        post_elo
                        assert_json_response({'response_type' => 'in_channel'})
                      end

                      should 'not create new players' do
                        assert_no_difference('Player.count', &method(:post_elo))
                      end

                      should 'update player ratings' do
                        post_elo
                        assert_not_equal @player1.rating, @player1.reload.rating
                        assert_not_equal @player2.rating, @player2.reload.rating
                      end
                    end
                  end

                  context 'player2 does not exist' do
                    context 'player1 wins' do
                      setup do
                        @params[:text] = '<@PLAYER1> and <@PLAYER2> beat <@PLAYER3> and <@PLAYER4>'
                      end

                      should 'log game' do
                        assert_difference('Game.count') do
                          post_elo
                          assert_predicate Game.where(player_one_id: @player1.id, result: 1), :exists?
                        end
                      end

                      should 'return congratulations message' do
                        post_elo
                        expected = /Congratulations to #{@player1.team_tag} \(\+\d+\) :.*: on defeating <@PLAYER3> and <@PLAYER4> \(-\d+\) :.*: at #{@game_type.game_name}!/
                        assert_json_response({'text' => expected})
                      end

                      should 'return response type in channel' do
                        post_elo
                        assert_json_response({'response_type' => 'in_channel'})
                      end

                      should 'create new player' do
                        assert_difference('Player.count', &method(:post_elo))
                      end

                      should 'update player ratings' do
                        post_elo
                        assert_not_equal @player1.rating, @player1.reload.rating
                        player2 = Player.where(slack_user_id: '@PLAYER3-@PLAYER4').take
                        assert_not_nil player2
                        assert_not_equal 1000, player2.rating
                      end
                    end

                    context 'player1 loses' do
                      setup do
                        @params[:text] = '<@PLAYER1> and <@PLAYER2> lost to <@PLAYER3> and <@PLAYER4>'
                      end

                      should 'log game' do
                        assert_difference('Game.count') do
                          post_elo
                          assert_predicate Game.where(player_one_id: @player1.id, result: 0), :exists?
                        end
                      end

                      should 'return congratulations message' do
                        post_elo
                        expected = /Congratulations to <@PLAYER3> and <@PLAYER4> \(\+\d+\) :.*: on defeating #{@player1.team_tag} \(-\d+\) :.*: at #{@game_type.game_name}!/
                        assert_json_response({'text' => expected})
                      end

                      should 'return response type in channel' do
                        post_elo
                        assert_json_response({'response_type' => 'in_channel'})
                      end

                      should 'create new player' do
                        assert_difference('Player.count', &method(:post_elo))
                      end

                      should 'update player ratings' do
                        post_elo
                        assert_not_equal @player1.rating, @player1.reload.rating
                        player2 = Player.where(slack_user_id: '@PLAYER3-@PLAYER4').take
                        assert_not_nil player2
                        assert_not_equal 1000, player2.rating
                      end
                    end

                    context 'draw' do
                      setup do
                        @params[:text] = '<@PLAYER1> and <@PLAYER2> tied <@PLAYER3> and <@PLAYER4>'
                      end

                      should 'log game' do
                        assert_difference('Game.count') do
                          post_elo
                          assert_predicate Game.where(player_one_id: @player1.id, result: 0.5), :exists?
                        end
                      end

                      should 'return congratulations message' do
                        post_elo
                        expected = /#{@player1.team_tag} \((\+|-)\d+\) :.*: tied <@PLAYER3> and <@PLAYER4> \((\+|-)\d+\) :.*: at #{@game_type.game_name}\./
                        assert_json_response({'text' => expected})
                      end

                      should 'return response type in channel' do
                        post_elo
                        assert_json_response({'response_type' => 'in_channel'})
                      end

                      should 'create new player' do
                        assert_difference('Player.count', &method(:post_elo))
                      end

                      should 'update player ratings' do
                        post_elo
                        assert_not_equal @player1.rating, @player1.reload.rating
                        player2 = Player.where(slack_user_id: '@PLAYER3-@PLAYER4').take
                        assert_not_nil player2
                        assert_not_equal 1000, player2.rating
                      end
                    end
                  end
                end

                context 'player1 does not exist' do
                  context 'player2 exists' do
                    setup do
                      @player2 = FactoryBot.create(:doubles_player2, game_type: @game_type, rating: 1200)
                    end

                    context 'player1 wins' do
                      setup do
                        @params[:text] = '<@PLAYER1> and <@PLAYER2> beat <@PLAYER3> and <@PLAYER4>'
                      end

                      should 'log game' do
                        assert_difference('Game.count') do
                          post_elo
                          assert_predicate Game.where(player_two_id: @player2.id, result: 1), :exists?
                        end
                      end

                      should 'return congratulations message' do
                        post_elo
                        expected = /Congratulations to <@PLAYER1> and <@PLAYER2> \(\+\d+\) :.*: on defeating #{@player2.team_tag} \(-\d+\) :.*: at #{@game_type.game_name}!/
                        assert_json_response({'text' => expected})
                      end

                      should 'return response type in channel' do
                        post_elo
                        assert_json_response({'response_type' => 'in_channel'})
                      end

                      should 'create new player' do
                        assert_difference('Player.count', &method(:post_elo))
                      end

                      should 'update player ratings' do
                        post_elo
                        player1 = Player.where(slack_user_id: '@PLAYER1-@PLAYER2').take
                        assert_not_nil player1
                        assert_not_equal 1000, player1.rating
                        assert_not_equal @player2.rating, @player2.reload.rating
                      end
                    end

                    context 'player1 loses' do
                      setup do
                        @params[:text] = '<@PLAYER1> and <@PLAYER2> lost to <@PLAYER3> and <@PLAYER4>'
                      end

                      should 'log game' do
                        assert_difference('Game.count') do
                          post_elo
                          assert_predicate Game.where(player_two_id: @player2.id, result: 0), :exists?
                        end
                      end

                      should 'return congratulations message' do
                        post_elo
                        expected = /Congratulations to #{@player2.team_tag} \(\+\d+\) :.*: on defeating <@PLAYER1> and <@PLAYER2> \(-\d+\) :.*: at #{@game_type.game_name}!/
                        assert_json_response({'text' => expected})
                      end

                      should 'return response type in channel' do
                        post_elo
                        assert_json_response({'response_type' => 'in_channel'})
                      end

                      should 'create new player' do
                        assert_difference('Player.count', &method(:post_elo))
                      end

                      should 'update player ratings' do
                        post_elo
                        player1 = Player.where(slack_user_id: '@PLAYER1-@PLAYER2').take
                        assert_not_nil player1
                        assert_not_equal 1000, player1.rating
                        assert_not_equal @player2.rating, @player2.reload.rating
                      end
                    end

                    context 'draw' do
                      setup do
                        @params[:text] = '<@PLAYER1> and <@PLAYER2> tied <@PLAYER3> and <@PLAYER4>'
                      end

                      should 'log game' do
                        assert_difference('Game.count') do
                          post_elo
                          assert_predicate Game.where(player_two_id: @player2.id, result: 0.5), :exists?
                        end
                      end

                      should 'return congratulations message' do
                        post_elo
                        expected = /<@PLAYER1> and <@PLAYER2> \((\+|-)\d+\) :.*: tied #{@player2.team_tag} \((\+|-)\d+\) :.*: at #{@game_type.game_name}\./
                        assert_json_response({'text' => expected})
                      end

                      should 'return response type in channel' do
                        post_elo
                        assert_json_response({'response_type' => 'in_channel'})
                      end

                      should 'create new player' do
                        assert_difference('Player.count', &method(:post_elo))
                      end

                      should 'update player ratings' do
                        post_elo
                        player1 = Player.where(slack_user_id: '@PLAYER1-@PLAYER2').take
                        assert_not_nil player1
                        assert_not_equal 1000, player1.rating
                        assert_not_equal @player2.rating, @player2.reload.rating
                      end
                    end
                  end

                  context 'player2 does not exist' do
                    context 'player1 wins' do
                      setup do
                        @params[:text] = '<@PLAYER1> and <@PLAYER2> beat <@PLAYER3> and <@PLAYER4>'
                      end

                      should 'log game' do
                        assert_difference('Game.count') do
                          post_elo
                          assert_predicate Game.where(slack_team_id: 'SLACKTEAMID', result: 1), :exists?
                        end
                      end

                      should 'return congratulations message' do
                        post_elo
                        expected = /Congratulations to <@PLAYER1> and <@PLAYER2> \(\+\d+\) :.*: on defeating <@PLAYER3> and <@PLAYER4> \(-\d+\) :.*: at #{@game_type.game_name}!/
                        assert_json_response({'text' => expected})
                      end

                      should 'return response type in channel' do
                        post_elo
                        assert_json_response({'response_type' => 'in_channel'})
                      end

                      should 'create new players' do
                        assert_difference('Player.count', 2, &method(:post_elo))
                      end

                      should 'update player ratings' do
                        post_elo
                        player1 = Player.where(slack_user_id: '@PLAYER1-@PLAYER2').take
                        assert_not_nil player1
                        assert_not_equal 1000, player1.rating
                        player2 = Player.where(slack_user_id: '@PLAYER3-@PLAYER4').take
                        assert_not_nil player2
                        assert_not_equal 1000, player2.rating
                      end
                    end

                    context 'player1 loses' do
                      setup do
                        @params[:text] = '<@PLAYER1> and <@PLAYER2> lost to <@PLAYER3> and <@PLAYER4>'
                      end

                      should 'log game' do
                        assert_difference('Game.count') do
                          post_elo
                          assert_predicate Game.where(slack_team_id: 'SLACKTEAMID', result: 0), :exists?
                        end
                      end

                      should 'return congratulations message' do
                        post_elo
                        expected = /Congratulations to <@PLAYER3> and <@PLAYER4> \(\+\d+\) :.*: on defeating <@PLAYER1> and <@PLAYER2> \(-\d+\) :.*: at #{@game_type.game_name}!/
                        assert_json_response({'text' => expected})
                      end

                      should 'return response type in channel' do
                        post_elo
                        assert_json_response({'response_type' => 'in_channel'})
                      end

                      should 'create new players' do
                        assert_difference('Player.count', 2, &method(:post_elo))
                      end

                      should 'update player ratings' do
                        post_elo
                        player1 = Player.where(slack_user_id: '@PLAYER1-@PLAYER2').take
                        assert_not_nil player1
                        assert_not_equal 1000, player1.rating
                        player2 = Player.where(slack_user_id: '@PLAYER3-@PLAYER4').take
                        assert_not_nil player2
                        assert_not_equal 1000, player2.rating
                      end
                    end

                    context 'draw' do
                      setup do
                        @params[:text] = '<@PLAYER1> and <@PLAYER2> tied <@PLAYER3> and <@PLAYER4>'
                      end

                      should 'log game' do
                        assert_difference('Game.count') do
                          post_elo
                          assert_predicate Game.where(slack_team_id: 'SLACKTEAMID', result: 0.5), :exists?
                        end
                      end

                      should 'return congratulations message' do
                        post_elo
                        expected = /<@PLAYER1> and <@PLAYER2> \((\+|-)\d+\) :.*: tied <@PLAYER3> and <@PLAYER4> \((\+|-)\d+\) :.*: at #{@game_type.game_name}\./
                        assert_json_response({'text' => expected})
                      end

                      should 'return response type in channel' do
                        post_elo
                        assert_json_response({'response_type' => 'in_channel'})
                      end

                      should 'create new players' do
                        assert_difference('Player.count', 2, &method(:post_elo))
                      end
                    end
                  end
                end
              end
            end

            context 'uneven' do
              setup do
                @params[:text] = "<@PLAYER1> and <@PLAYER2> beat <@PLAYER3>"
              end

              should 'return uneven message' do
                assert_no_difference('Game.count', &method(:post_elo))
                assert_simple_response "2 on 1 isn't very fair :dusty_stick:"
              end
            end

            # context 'no third-party' do
            #   setup do
            #     @params[:text] = "<@CURRENTUSER> beat <@PLAYER1>"
            #   end

            #   should 'return third party message' do
            #     assert_no_difference('Game.count', &method(:post_elo))
            #     assert_simple_response "A third-party witness must enter the game for it to count."
            #   end
            # end

            context 'areyoukiddingme' do
              %w(@USLACKBOT !channel !here).each do |player1|
                context player1 do
                  setup do
                    @params[:text] = "<#{player1}> beat <@PLAYER2>"
                  end

                  should 'return areyoukiddingme message' do
                    assert_no_difference('Game.count', &method(:post_elo))
                    assert_simple_response ":areyoukiddingme:"
                  end
                end
              end
            end

            context 'same player more than once' do
              context 'singles' do
                setup do
                  @params[:text] = "<@PLAYER1> beat <@PLAYER1>"
                end

                should 'return same player message' do
                  assert_no_difference('Game.count', &method(:post_elo))
                  assert_simple_response "Am I seeing double or did you enter the same person multiple times? :twinsparrot:"
                end
              end

              context 'doubles' do
                context 'different teams' do
                  setup do
                    @params[:text] = "<@PLAYER1> and <@PLAYER2> beat <@PLAYER1> and <@PLAYER3>"
                  end

                  should 'return same player message' do
                    assert_no_difference('Game.count', &method(:post_elo))
                    assert_simple_response "Am I seeing double or did you enter the same person multiple times? :twinsparrot:"
                  end
                end

                context 'same team' do
                  setup do
                    @params[:text] = "<@PLAYER1> and <@PLAYER1> beat <@PLAYER2> and <@PLAYER3>"
                  end

                  should 'return same player message' do
                    assert_no_difference('Game.count', &method(:post_elo))
                    assert_simple_response "Am I seeing double or did you enter the same person multiple times? :twinsparrot:"
                  end
                end
              end
            end

            context 'invalid game name' do
              setup do
                @params[:text] = "<@PLAYER1> beat <@PLAYER2> at foobar"
              end

              should 'return invalid game message' do
                assert_no_difference('Game.count', &method(:post_elo))
                assert_simple_response "Sorry! :sweat_smile: We couldn't determine what game you're referring to. Please make sure the game you're referring to is registered (`/elo games`) and if it isn't, please register it (`/elo register [game]`)."
              end
            end
          end
        end
      end

      context 'w/o slack signature' do
        should 'return unauthorized' do
          post_elo with_signature: false
          assert_response :unauthorized
        end
      end
    end
  end

  def post_elo(with_signature: true)
    if with_signature
      @request.headers['X-Slack-Request-Timestamp'] = Time.now.to_i
      @request.headers['X-Slack-Signature'] = SlackHelper.signature(timestamp: request.headers['X-Slack-Request-Timestamp'], raw_body: @params.to_query)
    end
    post :elo, params: @params
  end

  def assert_simple_response(text, response_type: 'ephemeral')
    assert_json_response(expected_response(text: text, response_type: response_type))
  end

  def assert_help_message
    attachments = [
        {
            text:
                "`/elo [@winner] defeated [@loser] at [game]` - Logs a game between these players and updates their ratings accordingly.\n" <<
                    "`/elo [@player1] tied [@player2] at [game]` - Logs a tie game between these players and updates their ratings accordingly.\n" <<
                    "`/elo leaderboard [game]` - Displays the leaderboard for the specified game.\n" <<
                    "`/elo rating [@player] [game]` - Displays your Elo rating for all types of games you've played. (Optional parameters allow you to filter to a specific game or view someone else's stats.)\n" <<
                    "`/elo games` - Lists all registered games for this team. (a.k.a. Valid inputs for [game] in other commands).\n" <<
                    "`/elo register [game]` - Registers this as a type of game that this team plays.\n"
        }
    ]
    assert_json_response(expected_response(text: ":wave: Need some help with `/elo`? Here are some useful commands:", attachments: attachments))
  end

  def expected_response(text: nil, response_type: 'ephemeral', attachments: [])
    {
        response_type: response_type,
        text: text,
        attachments: attachments
    }.as_json
  end
end
