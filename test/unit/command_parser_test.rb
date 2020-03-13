require 'test_helper'

class CommandParserTest < ActiveSupport::TestCase
  context 'CommandParserTest' do
    setup do
      @game_type = FactoryBot.create(:game_type, :with_slack_team_id)
      @current_user = FactoryBot.create(:player, :with_slack_team_id, :singles, slack_user_id: '@CURRENTUSER', game_type: @game_type)
      @player1 = FactoryBot.create(:player1, game_type: @game_type)
      @player2 = FactoryBot.create(:player2, game_type: @game_type)
      @doubles_player1 = FactoryBot.create(:doubles_player1, game_type: @game_type)
      @doubles_player2 = FactoryBot.create(:doubles_player2, game_type: @game_type)
    end

    context 'command:stats' do
      %w(rating ranking stats statistics).each do |keyword|
        context "keyword:#{keyword}" do
          context 'no player indicated' do
            context 'game indicated' do
              should 'correctly parse command' do
                params = {
                    text: "#{keyword} #{@game_type.game_name}",
                    user_id: 'CURRENTUSER',
                    team_id: 'SLACKTEAMID',
                    channel_name: 'random'
                }
                expected = {
                    teams: [@current_user.slack_user_id, nil],
                    players: [@current_user.slack_user_id],
                    team_size: 1,
                    action: :stats,
                    game_name: @game_type.game_name,
                    game_type: @game_type
                }
                parsed = CommandParser.new(params).parse
                assert_equivalent expected, parsed, allow_nil: true
              end
            end

            context 'game not indicated' do
              context 'in channel for game' do
                should 'correctly parse command' do
                  params = {
                      text: keyword,
                      user_id: 'CURRENTUSER',
                      team_id: 'SLACKTEAMID',
                      channel_name: @game_type.game_name
                  }
                  expected = {
                      teams: [@current_user.slack_user_id, nil],
                      players: [@current_user.slack_user_id],
                      team_size: 1,
                      action: :stats,
                      game_name: @game_type.game_name,
                      game_type: @game_type
                  }
                  parsed = CommandParser.new(params).parse
                  assert_equivalent expected, parsed, allow_nil: true
                end
              end

              context 'not in channel for game' do
                should 'correctly parse command' do
                  params = {
                      text: keyword,
                      user_id: 'CURRENTUSER',
                      team_id: 'SLACKTEAMID',
                      channel_name: 'random'
                  }
                  expected = {
                      teams: [@current_user.slack_user_id, nil],
                      players: [@current_user.slack_user_id],
                      team_size: 1,
                      action: :stats,
                      game_name: nil,
                      game_type: nil
                  }
                  parsed = CommandParser.new(params).parse
                  assert_equivalent expected, parsed, allow_nil: true
                end
              end
            end
          end

          context 'single player indicated' do
            context 'game indicated' do
              should 'correctly parse command' do
                params = {
                    text: "#{keyword} #{@game_type.game_name} #{@player1.team_tag}",
                    user_id: 'CURRENTUSER',
                    team_id: 'SLACKTEAMID',
                    channel_name: 'random'
                }
                expected = {
                    teams: [@player1.slack_user_id, nil],
                    players: [@player1.slack_user_id],
                    team_size: 1,
                    action: :stats,
                    game_name: @game_type.game_name,
                    game_type: @game_type
                }
                parsed = CommandParser.new(params).parse
                assert_equivalent expected, parsed, allow_nil: true
              end
            end

            context 'game not indicated' do
              context 'in channel for game' do
                should 'correctly parse command' do
                  params = {
                      text: "#{keyword} #{@player1.team_tag}",
                      user_id: 'CURRENTUSER',
                      team_id: 'SLACKTEAMID',
                      channel_name: @game_type.game_name
                  }
                  expected = {
                      teams: [@player1.slack_user_id, nil],
                      players: [@player1.slack_user_id],
                      team_size: 1,
                      action: :stats,
                      game_name: @game_type.game_name,
                      game_type: @game_type
                  }
                  parsed = CommandParser.new(params).parse
                  assert_equivalent expected, parsed, allow_nil: true
                end
              end

              context 'not in channel for game' do
                should 'correctly parse command' do
                  params = {
                      text: "#{keyword} #{@player1.team_tag}",
                      user_id: 'CURRENTUSER',
                      team_id: 'SLACKTEAMID',
                      channel_name: 'random'
                  }
                  expected = {
                      teams: [@player1.slack_user_id, nil],
                      players: [@player1.slack_user_id],
                      team_size: 1,
                      action: :stats,
                      game_name: nil,
                      game_type: nil
                  }
                  parsed = CommandParser.new(params).parse
                  assert_equivalent expected, parsed, allow_nil: true
                end
              end
            end
          end

          context 'multiple players indicated' do
            context 'game indicated' do
              should 'correctly parse command' do
                params = {
                    text: "#{keyword} #{@game_type.game_name} #{@doubles_player1.team_tag}",
                    user_id: 'CURRENTUSER',
                    team_id: 'SLACKTEAMID',
                    channel_name: 'random'
                }
                expected = {
                    teams: [@doubles_player1.slack_user_id, nil],
                    players: @doubles_player1.slack_user_id.split('-'),
                    team_size: 2,
                    action: :stats,
                    game_name: @game_type.game_name,
                    game_type: @game_type
                }
                parsed = CommandParser.new(params).parse
                assert_equivalent expected, parsed, allow_nil: true
              end
            end

            context 'game not indicated' do
              context 'in channel for game' do
                should 'correctly parse command' do
                  params = {
                      text: "#{keyword} #{@doubles_player1.team_tag}",
                      user_id: 'CURRENTUSER',
                      team_id: 'SLACKTEAMID',
                      channel_name: @game_type.game_name
                  }
                  expected = {
                      teams: [@doubles_player1.slack_user_id, nil],
                      players: @doubles_player1.slack_user_id.split('-'),
                      team_size: 2,
                      action: :stats,
                      game_name: @game_type.game_name,
                      game_type: @game_type
                  }
                  parsed = CommandParser.new(params).parse
                  assert_equivalent expected, parsed, allow_nil: true
                end
              end

              context 'not in channel for game' do
                should 'correctly parse command' do
                  params = {
                      text: "#{keyword} #{@doubles_player1.team_tag}",
                      user_id: 'CURRENTUSER',
                      team_id: 'SLACKTEAMID',
                      channel_name: 'random'
                  }
                  expected = {
                      teams: [@doubles_player1.slack_user_id, nil],
                      players: @doubles_player1.slack_user_id.split('-'),
                      team_size: 2,
                      action: :stats,
                      game_name: nil,
                      game_type: nil
                  }
                  parsed = CommandParser.new(params).parse
                  assert_equivalent expected, parsed, allow_nil: true
                end
              end
            end
          end
        end
      end
    end

    context 'command:leaderboard' do
      context 'keyword:leaderboard' do
        context 'game indicated' do
          should 'correctly parse command' do
            params = {
                text: "leaderboard #{@game_type.game_name}",
                user_id: 'CURRENTUSER',
                team_id: 'SLACKTEAMID',
                channel_name: 'random'
            }
            expected = {
                action: :leaderboard,
                game_name: @game_type.game_name,
                game_type: @game_type
            }
            parsed = CommandParser.new(params).parse
            assert_equivalent expected, parsed
          end
        end

        context 'game not indicated' do
          context 'in channel for game' do
            should 'correctly parse command' do
              params = {
                  text: 'leaderboard',
                  user_id: 'CURRENTUSER',
                  team_id: 'SLACKTEAMID',
                  channel_name: @game_type.game_name
              }
              expected = {
                  action: :leaderboard,
                  game_name: @game_type.game_name,
                  game_type: @game_type
              }
              parsed = CommandParser.new(params).parse
              assert_equivalent expected, parsed
            end
          end

          context 'not in channel for game' do
            should 'correctly parse command' do
              params = {
                  text: 'leaderboard',
                  user_id: 'CURRENTUSER',
                  team_id: 'SLACKTEAMID',
                  channel_name: 'random'
              }
              expected = {
                  action: :leaderboard,
                  game_name: nil,
                  game_type: nil
              }
              parsed = CommandParser.new(params).parse
              assert_equivalent expected, parsed, allow_nil: true
            end
          end
        end
      end
    end

    context 'command:register' do
      context 'keyword:register' do
        context 'game indicated' do
          context 'game already exists' do
            should 'correct parse command' do
              params = {
                  text: "register #{@game_type.game_name}",
                  user_id: 'CURRENTUSER',
                  team_id: 'SLACKTEAMID',
                  channel_name: 'random'
              }
              expected = {
                  action: :register,
                  game_name: @game_type.game_name,
                  game_type: @game_type
              }
              parsed = CommandParser.new(params).parse
              assert_equivalent expected, parsed
            end
          end

          context 'game does not exist' do
            should 'correct parse command' do
              params = {
                  text: 'register new_game',
                  user_id: 'CURRENTUSER',
                  team_id: 'SLACKTEAMID',
                  channel_name: 'random'
              }
              expected = {
                  action: :register,
                  game_name: 'new_game',
                  game_type: nil
              }
              parsed = CommandParser.new(params).parse
              assert_equivalent expected, parsed, allow_nil: true
            end
          end
        end

        context 'game not indicated' do
          context 'in appropriate channel' do
            context 'game already exists' do
              should 'correct parse command' do
                params = {
                    text: 'register',
                    user_id: 'CURRENTUSER',
                    team_id: 'SLACKTEAMID',
                    channel_name: @game_type.game_name
                }
                expected = {
                    action: :register,
                    game_name: @game_type.game_name,
                    game_type: @game_type
                }
                parsed = CommandParser.new(params).parse
                assert_equivalent expected, parsed
              end
            end

            context 'game does not exist' do
              should 'correct parse command' do
                params = {
                    text: 'register',
                    user_id: 'CURRENTUSER',
                    team_id: 'SLACKTEAMID',
                    channel_name: 'new_game'
                }
                expected = {
                    action: :register,
                    game_name: 'new_game',
                    game_type: nil
                }
                parsed = CommandParser.new(params).parse
                assert_equivalent expected, parsed, allow_nil: true
              end
            end
          end

          context 'in private group' do
            should 'correct parse command' do
              params = {
                  text: 'register',
                  user_id: 'CURRENTUSER',
                  team_id: 'SLACKTEAMID',
                  channel_name: 'privategroup'
              }
              expected = {
                  action: :register,
                  game_name: nil,
                  game_type: nil
              }
              parsed = CommandParser.new(params).parse
              assert_equivalent expected, parsed, allow_nil: true
            end
          end

          context 'in direct message' do
            should 'correct parse command' do
              params = {
                  text: 'register',
                  user_id: 'CURRENTUSER',
                  team_id: 'SLACKTEAMID',
                  channel_name: 'directmessage'
              }
              expected = {
                  action: :register,
                  game_name: nil,
                  game_type: nil
              }
              parsed = CommandParser.new(params).parse
              assert_equivalent expected, parsed, allow_nil: true
            end
          end
        end
      end
    end

    context 'command:games' do
      context 'keyword:games' do
        should 'correctly parse command' do
          params = {
              text: 'games',
              user_id: 'CURRENTUSER',
              team_id: 'SLACKTEAMID',
              channel_name: 'random'
          }
          expected = {
              action: :games
          }
          parsed = CommandParser.new(params).parse
          assert_equivalent expected, parsed
        end
      end
    end

    context 'command:help' do
      context 'keyword:help' do
        should 'correctly parse command' do
          params = {
              text: 'help',
              user_id: 'CURRENTUSER',
              team_id: 'SLACKTEAMID',
              channel_name: 'random'
          }
          expected = {
              action: :help
          }
          parsed = CommandParser.new(params).parse
          assert_equivalent expected, parsed
        end
      end
    end

    context 'command:win' do
      CommandParser::WIN_TERMS.each do |term|
        context "keyword:#{term.inspect}" do
          context 'singles' do
            context 'w/ specified game' do
              should 'parse command correctly' do
                params = {
                    text: "#{@player1.team_tag} #{term} #{@player2.team_tag} at #{@game_type.game_name}",
                    user_id: 'CURRENTUSER',
                    team_id: 'SLACKTEAMID',
                    channel_name: 'random'
                }
                expected = {
                    teams: [@player1.slack_user_id, @player2.slack_user_id],
                    players: [@player1.slack_user_id, @player2.slack_user_id],
                    team_size: 1,
                    action: :win,
                    game_name: @game_type.game_name,
                    game_type: @game_type
                }
                parsed = CommandParser.new(params).parse
                assert_equivalent expected, parsed
              end
            end

            context 'w/o specified game' do
              context 'in game channel' do
                should 'parse command correctly' do
                  params = {
                      text: "#{@player1.team_tag} #{term} #{@player2.team_tag}",
                      user_id: 'CURRENTUSER',
                      team_id: 'SLACKTEAMID',
                      channel_name: @game_type.game_name
                  }
                  expected = {
                      teams: [@player1.slack_user_id, @player2.slack_user_id],
                      players: [@player1.slack_user_id, @player2.slack_user_id],
                      team_size: 1,
                      action: :win,
                      game_name: @game_type.game_name,
                      game_type: @game_type
                  }
                  parsed = CommandParser.new(params).parse
                  assert_equivalent expected, parsed
                end
              end

              context 'in non-game channel' do
                should 'parse command correctly' do
                  params = {
                      text: "#{@player1.team_tag} #{term} #{@player2.team_tag}",
                      user_id: 'CURRENTUSER',
                      team_id: 'SLACKTEAMID',
                      channel_name: 'random'
                  }
                  expected = {
                      teams: [@player1.slack_user_id, @player2.slack_user_id],
                      players: [@player1.slack_user_id, @player2.slack_user_id],
                      team_size: 1,
                      action: :win,
                      game_name: nil,
                      game_type: nil
                  }
                  parsed = CommandParser.new(params).parse
                  assert_equivalent expected, parsed, allow_nil: true
                end
              end

              context 'in directmessage' do
                should 'parse command correctly' do
                  params = {
                      text: "#{@player1.team_tag} #{term} #{@player2.team_tag}",
                      user_id: 'CURRENTUSER',
                      team_id: 'SLACKTEAMID',
                      channel_name: 'directmessage'
                  }
                  expected = {
                      teams: [@player1.slack_user_id, @player2.slack_user_id],
                      players: [@player1.slack_user_id, @player2.slack_user_id],
                      team_size: 1,
                      action: :win,
                      game_name: nil,
                      game_type: nil
                  }
                  parsed = CommandParser.new(params).parse
                  assert_equivalent expected, parsed, allow_nil: true
                end
              end

              context 'in privategroup' do
                should 'parse command correctly' do
                  params = {
                      text: "#{@player1.team_tag} #{term} #{@player2.team_tag}",
                      user_id: 'CURRENTUSER',
                      team_id: 'SLACKTEAMID',
                      channel_name: 'privategroupe'
                  }
                  expected = {
                      teams: [@player1.slack_user_id, @player2.slack_user_id],
                      players: [@player1.slack_user_id, @player2.slack_user_id],
                      team_size: 1,
                      action: :win,
                      game_name: nil,
                      game_type: nil
                  }
                  parsed = CommandParser.new(params).parse
                  assert_equivalent expected, parsed, allow_nil: true
                end
              end
            end
          end

          context 'doubles' do
            context 'w/ specified game' do
              should 'parse command correctly' do
                params = {
                    text: "#{@doubles_player1.team_tag} #{term} #{@doubles_player2.team_tag} at #{@game_type.game_name}",
                    user_id: 'CURRENTUSER',
                    team_id: 'SLACKTEAMID',
                    channel_name: 'random'
                }
                expected = {
                    teams: [@doubles_player1.slack_user_id, @doubles_player2.slack_user_id],
                    players: @doubles_player1.slack_user_id.split('-') + @doubles_player2.slack_user_id.split('-'),
                    team_size: 2,
                    action: :win,
                    game_name: @game_type.game_name,
                    game_type: @game_type
                }
                parsed = CommandParser.new(params).parse
                assert_equivalent expected, parsed
              end
            end

            context 'w/o specified game' do
              context 'in game channel' do
                should 'parse command correctly' do
                  params = {
                      text: "#{@doubles_player1.team_tag} #{term} #{@doubles_player2.team_tag}",
                      user_id: 'CURRENTUSER',
                      team_id: 'SLACKTEAMID',
                      channel_name: @game_type.game_name
                  }
                  expected = {
                      teams: [@doubles_player1.slack_user_id, @doubles_player2.slack_user_id],
                      players: @doubles_player1.slack_user_id.split('-') + @doubles_player2.slack_user_id.split('-'),
                      team_size: 2,
                      action: :win,
                      game_name: @game_type.game_name,
                      game_type: @game_type
                  }
                  parsed = CommandParser.new(params).parse
                  assert_equivalent expected, parsed
                end
              end

              context 'in non-game channel' do
                should 'parse command correctly' do
                  params = {
                      text: "#{@doubles_player1.team_tag} #{term} #{@doubles_player2.team_tag}",
                      user_id: 'CURRENTUSER',
                      team_id: 'SLACKTEAMID',
                      channel_name: 'random'
                  }
                  expected = {
                      teams: [@doubles_player1.slack_user_id, @doubles_player2.slack_user_id],
                      players: @doubles_player1.slack_user_id.split('-') + @doubles_player2.slack_user_id.split('-'),
                      team_size: 2,
                      action: :win,
                      game_name: nil,
                      game_type: nil
                  }
                  parsed = CommandParser.new(params).parse
                  assert_equivalent expected, parsed, allow_nil: true
                end
              end

              context 'in directmessage' do
                should 'parse command correctly' do
                  params = {
                      text: "#{@doubles_player1.team_tag} #{term} #{@doubles_player2.team_tag}",
                      user_id: 'CURRENTUSER',
                      team_id: 'SLACKTEAMID',
                      channel_name: 'directmessage'
                  }
                  expected = {
                      teams: [@doubles_player1.slack_user_id, @doubles_player2.slack_user_id],
                      players: @doubles_player1.slack_user_id.split('-') + @doubles_player2.slack_user_id.split('-'),
                      team_size: 2,
                      action: :win,
                      game_name: nil,
                      game_type: nil
                  }
                  parsed = CommandParser.new(params).parse
                  assert_equivalent expected, parsed, allow_nil: true
                end
              end

              context 'in privategroup' do
                should 'parse command correctly' do
                  params = {
                      text: "#{@doubles_player1.team_tag} #{term} #{@doubles_player2.team_tag}",
                      user_id: 'CURRENTUSER',
                      team_id: 'SLACKTEAMID',
                      channel_name: 'privategroup'
                  }
                  expected = {
                      teams: [@doubles_player1.slack_user_id, @doubles_player2.slack_user_id],
                      players: @doubles_player1.slack_user_id.split('-') + @doubles_player2.slack_user_id.split('-'),
                      team_size: 2,
                      action: :win,
                      game_name: nil,
                      game_type: nil
                  }
                  parsed = CommandParser.new(params).parse
                  assert_equivalent expected, parsed, allow_nil: true
                end
              end
            end
          end

          context 'uneven' do
            context 'w/ specified game' do
              should 'parse command correctly' do
                params = {
                    text: "#{@doubles_player1.team_tag} #{term} #{@doubles_player2.team_tag} at #{@game_type.game_name}",
                    user_id: 'CURRENTUSER',
                    team_id: 'SLACKTEAMID',
                    channel_name: 'random'
                }
                expected = {
                    teams: [@doubles_player1.slack_user_id, @doubles_player2.slack_user_id],
                    players: @doubles_player1.slack_user_id.split('-') + @doubles_player2.slack_user_id.split('-'),
                    team_size: 2,
                    action: :win,
                    game_name: @game_type.game_name,
                    game_type: @game_type
                }
                parsed = CommandParser.new(params).parse
                assert_equivalent expected, parsed
              end
            end

            context 'w/o specified game' do
              context 'in game channel' do
                should 'parse command correctly' do
                  params = {
                      text: "#{@player1.team_tag} #{term} #{@doubles_player2.team_tag}",
                      user_id: 'CURRENTUSER',
                      team_id: 'SLACKTEAMID',
                      channel_name: @game_type.game_name
                  }
                  expected = {
                      teams: [@player1.slack_user_id, @doubles_player2.slack_user_id],
                      players: @player1.slack_user_id.split('-') + @doubles_player2.slack_user_id.split('-'),
                      team_size: :uneven,
                      action: :win,
                      game_name: @game_type.game_name,
                      game_type: @game_type
                  }
                  parsed = CommandParser.new(params).parse
                  assert_equivalent expected, parsed
                end
              end

              context 'in non-game channel' do
                should 'parse command correctly' do
                  params = {
                      text: "#{@player1.team_tag} #{term} #{@doubles_player2.team_tag}",
                      user_id: 'CURRENTUSER',
                      team_id: 'SLACKTEAMID',
                      channel_name: 'random'
                  }
                  expected = {
                      teams: [@player1.slack_user_id, @doubles_player2.slack_user_id],
                      players: @player1.slack_user_id.split('-') + @doubles_player2.slack_user_id.split('-'),
                      team_size: :uneven,
                      action: :win,
                      game_name: nil,
                      game_type: nil
                  }
                  parsed = CommandParser.new(params).parse
                  assert_equivalent expected, parsed, allow_nil: true
                end
              end

              context 'in directmessage' do
                should 'parse command correctly' do
                  params = {
                      text: "#{@player1.team_tag} #{term} #{@doubles_player2.team_tag}",
                      user_id: 'CURRENTUSER',
                      team_id: 'SLACKTEAMID',
                      channel_name: 'directmessage'
                  }
                  expected = {
                      teams: [@player1.slack_user_id, @doubles_player2.slack_user_id],
                      players: @player1.slack_user_id.split('-') + @doubles_player2.slack_user_id.split('-'),
                      team_size: :uneven,
                      action: :win,
                      game_name: nil,
                      game_type: nil
                  }
                  parsed = CommandParser.new(params).parse
                  assert_equivalent expected, parsed, allow_nil: true
                end
              end

              context 'in privategroup' do
                should 'parse command correctly' do
                  params = {
                      text: "#{@player1.team_tag} #{term} #{@doubles_player2.team_tag}",
                      user_id: 'CURRENTUSER',
                      team_id: 'SLACKTEAMID',
                      channel_name: 'privategroup'
                  }
                  expected = {
                      teams: [@player1.slack_user_id, @doubles_player2.slack_user_id],
                      players: @player1.slack_user_id.split('-') + @doubles_player2.slack_user_id.split('-'),
                      team_size: :uneven,
                      action: :win,
                      game_name: nil,
                      game_type: nil
                  }
                  parsed = CommandParser.new(params).parse
                  assert_equivalent expected, parsed, allow_nil: true
                end
              end
            end
          end
        end
      end
    end

    context 'command:loss' do
      CommandParser::LOSS_TERMS.each do |term|
        context "keyword:#{term.inspect}" do
          context 'singles' do
            context 'w/ specified game' do
              should 'parse command correctly' do
                params = {
                    text: "#{@player1.team_tag} #{term} #{@player2.team_tag} at #{@game_type.game_name}",
                    user_id: 'CURRENTUSER',
                    team_id: 'SLACKTEAMID',
                    channel_name: 'random'
                }
                expected = {
                    teams: [@player1.slack_user_id, @player2.slack_user_id],
                    players: [@player1.slack_user_id, @player2.slack_user_id],
                    team_size: 1,
                    action: :loss,
                    game_name: @game_type.game_name,
                    game_type: @game_type
                }
                parsed = CommandParser.new(params).parse
                assert_equivalent expected, parsed
              end
            end

            context 'w/o specified game' do
              context 'in game channel' do
                should 'parse command correctly' do
                  params = {
                      text: "#{@player1.team_tag} #{term} #{@player2.team_tag}",
                      user_id: 'CURRENTUSER',
                      team_id: 'SLACKTEAMID',
                      channel_name: @game_type.game_name
                  }
                  expected = {
                      teams: [@player1.slack_user_id, @player2.slack_user_id],
                      players: [@player1.slack_user_id, @player2.slack_user_id],
                      team_size: 1,
                      action: :loss,
                      game_name: @game_type.game_name,
                      game_type: @game_type
                  }
                  parsed = CommandParser.new(params).parse
                  assert_equivalent expected, parsed
                end
              end

              context 'in non-game channel' do
                should 'parse command correctly' do
                  params = {
                      text: "#{@player1.team_tag} #{term} #{@player2.team_tag}",
                      user_id: 'CURRENTUSER',
                      team_id: 'SLACKTEAMID',
                      channel_name: 'random'
                  }
                  expected = {
                      teams: [@player1.slack_user_id, @player2.slack_user_id],
                      players: [@player1.slack_user_id, @player2.slack_user_id],
                      team_size: 1,
                      action: :loss,
                      game_name: nil,
                      game_type: nil
                  }
                  parsed = CommandParser.new(params).parse
                  assert_equivalent expected, parsed, allow_nil: true
                end
              end

              context 'in directmessage' do
                should 'parse command correctly' do
                  params = {
                      text: "#{@player1.team_tag} #{term} #{@player2.team_tag}",
                      user_id: 'CURRENTUSER',
                      team_id: 'SLACKTEAMID',
                      channel_name: 'directmessage'
                  }
                  expected = {
                      teams: [@player1.slack_user_id, @player2.slack_user_id],
                      players: [@player1.slack_user_id, @player2.slack_user_id],
                      team_size: 1,
                      action: :loss,
                      game_name: nil,
                      game_type: nil
                  }
                  parsed = CommandParser.new(params).parse
                  assert_equivalent expected, parsed, allow_nil: true
                end
              end

              context 'in privategroup' do
                should 'parse command correctly' do
                  params = {
                      text: "#{@player1.team_tag} #{term} #{@player2.team_tag}",
                      user_id: 'CURRENTUSER',
                      team_id: 'SLACKTEAMID',
                      channel_name: 'privategroupe'
                  }
                  expected = {
                      teams: [@player1.slack_user_id, @player2.slack_user_id],
                      players: [@player1.slack_user_id, @player2.slack_user_id],
                      team_size: 1,
                      action: :loss,
                      game_name: nil,
                      game_type: nil
                  }
                  parsed = CommandParser.new(params).parse
                  assert_equivalent expected, parsed, allow_nil: true
                end
              end
            end
          end

          context 'doubles' do
            context 'w/ specified game' do
              should 'parse command correctly' do
                params = {
                    text: "#{@doubles_player1.team_tag} #{term} #{@doubles_player2.team_tag} at #{@game_type.game_name}",
                    user_id: 'CURRENTUSER',
                    team_id: 'SLACKTEAMID',
                    channel_name: 'random'
                }
                expected = {
                    teams: [@doubles_player1.slack_user_id, @doubles_player2.slack_user_id],
                    players: @doubles_player1.slack_user_id.split('-') + @doubles_player2.slack_user_id.split('-'),
                    team_size: 2,
                    action: :loss,
                    game_name: @game_type.game_name,
                    game_type: @game_type
                }
                parsed = CommandParser.new(params).parse
                assert_equivalent expected, parsed
              end
            end

            context 'w/o specified game' do
              context 'in game channel' do
                should 'parse command correctly' do
                  params = {
                      text: "#{@doubles_player1.team_tag} #{term} #{@doubles_player2.team_tag}",
                      user_id: 'CURRENTUSER',
                      team_id: 'SLACKTEAMID',
                      channel_name: @game_type.game_name
                  }
                  expected = {
                      teams: [@doubles_player1.slack_user_id, @doubles_player2.slack_user_id],
                      players: @doubles_player1.slack_user_id.split('-') + @doubles_player2.slack_user_id.split('-'),
                      team_size: 2,
                      action: :loss,
                      game_name: @game_type.game_name,
                      game_type: @game_type
                  }
                  parsed = CommandParser.new(params).parse
                  assert_equivalent expected, parsed
                end
              end

              context 'in non-game channel' do
                should 'parse command correctly' do
                  params = {
                      text: "#{@doubles_player1.team_tag} #{term} #{@doubles_player2.team_tag}",
                      user_id: 'CURRENTUSER',
                      team_id: 'SLACKTEAMID',
                      channel_name: 'random'
                  }
                  expected = {
                      teams: [@doubles_player1.slack_user_id, @doubles_player2.slack_user_id],
                      players: @doubles_player1.slack_user_id.split('-') + @doubles_player2.slack_user_id.split('-'),
                      team_size: 2,
                      action: :loss,
                      game_name: nil,
                      game_type: nil
                  }
                  parsed = CommandParser.new(params).parse
                  assert_equivalent expected, parsed, allow_nil: true
                end
              end

              context 'in directmessage' do
                should 'parse command correctly' do
                  params = {
                      text: "#{@doubles_player1.team_tag} #{term} #{@doubles_player2.team_tag}",
                      user_id: 'CURRENTUSER',
                      team_id: 'SLACKTEAMID',
                      channel_name: 'directmessage'
                  }
                  expected = {
                      teams: [@doubles_player1.slack_user_id, @doubles_player2.slack_user_id],
                      players: @doubles_player1.slack_user_id.split('-') + @doubles_player2.slack_user_id.split('-'),
                      team_size: 2,
                      action: :loss,
                      game_name: nil,
                      game_type: nil
                  }
                  parsed = CommandParser.new(params).parse
                  assert_equivalent expected, parsed, allow_nil: true
                end
              end

              context 'in privategroup' do
                should 'parse command correctly' do
                  params = {
                      text: "#{@doubles_player1.team_tag} #{term} #{@doubles_player2.team_tag}",
                      user_id: 'CURRENTUSER',
                      team_id: 'SLACKTEAMID',
                      channel_name: 'privategroup'
                  }
                  expected = {
                      teams: [@doubles_player1.slack_user_id, @doubles_player2.slack_user_id],
                      players: @doubles_player1.slack_user_id.split('-') + @doubles_player2.slack_user_id.split('-'),
                      team_size: 2,
                      action: :loss,
                      game_name: nil,
                      game_type: nil
                  }
                  parsed = CommandParser.new(params).parse
                  assert_equivalent expected, parsed, allow_nil: true
                end
              end
            end
          end

          context 'uneven' do
            context 'w/ specified game' do
              should 'parse command correctly' do
                params = {
                    text: "#{@doubles_player1.team_tag} #{term} #{@doubles_player2.team_tag} at #{@game_type.game_name}",
                    user_id: 'CURRENTUSER',
                    team_id: 'SLACKTEAMID',
                    channel_name: 'random'
                }
                expected = {
                    teams: [@doubles_player1.slack_user_id, @doubles_player2.slack_user_id],
                    players: @doubles_player1.slack_user_id.split('-') + @doubles_player2.slack_user_id.split('-'),
                    team_size: 2,
                    action: :loss,
                    game_name: @game_type.game_name,
                    game_type: @game_type
                }
                parsed = CommandParser.new(params).parse
                assert_equivalent expected, parsed
              end
            end

            context 'w/o specified game' do
              context 'in game channel' do
                should 'parse command correctly' do
                  params = {
                      text: "#{@player1.team_tag} #{term} #{@doubles_player2.team_tag}",
                      user_id: 'CURRENTUSER',
                      team_id: 'SLACKTEAMID',
                      channel_name: @game_type.game_name
                  }
                  expected = {
                      teams: [@player1.slack_user_id, @doubles_player2.slack_user_id],
                      players: @player1.slack_user_id.split('-') + @doubles_player2.slack_user_id.split('-'),
                      team_size: :uneven,
                      action: :loss,
                      game_name: @game_type.game_name,
                      game_type: @game_type
                  }
                  parsed = CommandParser.new(params).parse
                  assert_equivalent expected, parsed
                end
              end

              context 'in non-game channel' do
                should 'parse command correctly' do
                  params = {
                      text: "#{@player1.team_tag} #{term} #{@doubles_player2.team_tag}",
                      user_id: 'CURRENTUSER',
                      team_id: 'SLACKTEAMID',
                      channel_name: 'random'
                  }
                  expected = {
                      teams: [@player1.slack_user_id, @doubles_player2.slack_user_id],
                      players: @player1.slack_user_id.split('-') + @doubles_player2.slack_user_id.split('-'),
                      team_size: :uneven,
                      action: :loss,
                      game_name: nil,
                      game_type: nil
                  }
                  parsed = CommandParser.new(params).parse
                  assert_equivalent expected, parsed, allow_nil: true
                end
              end

              context 'in directmessage' do
                should 'parse command correctly' do
                  params = {
                      text: "#{@player1.team_tag} #{term} #{@doubles_player2.team_tag}",
                      user_id: 'CURRENTUSER',
                      team_id: 'SLACKTEAMID',
                      channel_name: 'directmessage'
                  }
                  expected = {
                      teams: [@player1.slack_user_id, @doubles_player2.slack_user_id],
                      players: @player1.slack_user_id.split('-') + @doubles_player2.slack_user_id.split('-'),
                      team_size: :uneven,
                      action: :loss,
                      game_name: nil,
                      game_type: nil
                  }
                  parsed = CommandParser.new(params).parse
                  assert_equivalent expected, parsed, allow_nil: true
                end
              end

              context 'in privategroup' do
                should 'parse command correctly' do
                  params = {
                      text: "#{@player1.team_tag} #{term} #{@doubles_player2.team_tag}",
                      user_id: 'CURRENTUSER',
                      team_id: 'SLACKTEAMID',
                      channel_name: 'privategroup'
                  }
                  expected = {
                      teams: [@player1.slack_user_id, @doubles_player2.slack_user_id],
                      players: @player1.slack_user_id.split('-') + @doubles_player2.slack_user_id.split('-'),
                      team_size: :uneven,
                      action: :loss,
                      game_name: nil,
                      game_type: nil
                  }
                  parsed = CommandParser.new(params).parse
                  assert_equivalent expected, parsed, allow_nil: true
                end
              end
            end
          end
        end
      end
    end

    context 'command:draw' do
      CommandParser::DRAW_TERMS.each do |term|
        context "keyword:#{term.inspect}" do
          context 'singles' do
            context 'w/ specified game' do
              should 'parse command correctly' do
                params = {
                    text: "#{@player1.team_tag} #{term} #{@player2.team_tag} at #{@game_type.game_name}",
                    user_id: 'CURRENTUSER',
                    team_id: 'SLACKTEAMID',
                    channel_name: 'random'
                }
                expected = {
                    teams: [@player1.slack_user_id, @player2.slack_user_id],
                    players: [@player1.slack_user_id, @player2.slack_user_id],
                    team_size: 1,
                    action: :draw,
                    game_name: @game_type.game_name,
                    game_type: @game_type
                }
                parsed = CommandParser.new(params).parse
                assert_equivalent expected, parsed
              end
            end

            context 'w/o specified game' do
              context 'in game channel' do
                should 'parse command correctly' do
                  params = {
                      text: "#{@player1.team_tag} #{term} #{@player2.team_tag}",
                      user_id: 'CURRENTUSER',
                      team_id: 'SLACKTEAMID',
                      channel_name: @game_type.game_name
                  }
                  expected = {
                      teams: [@player1.slack_user_id, @player2.slack_user_id],
                      players: [@player1.slack_user_id, @player2.slack_user_id],
                      team_size: 1,
                      action: :draw,
                      game_name: @game_type.game_name,
                      game_type: @game_type
                  }
                  parsed = CommandParser.new(params).parse
                  assert_equivalent expected, parsed
                end
              end

              context 'in non-game channel' do
                should 'parse command correctly' do
                  params = {
                      text: "#{@player1.team_tag} #{term} #{@player2.team_tag}",
                      user_id: 'CURRENTUSER',
                      team_id: 'SLACKTEAMID',
                      channel_name: 'random'
                  }
                  expected = {
                      teams: [@player1.slack_user_id, @player2.slack_user_id],
                      players: [@player1.slack_user_id, @player2.slack_user_id],
                      team_size: 1,
                      action: :draw,
                      game_name: nil,
                      game_type: nil
                  }
                  parsed = CommandParser.new(params).parse
                  assert_equivalent expected, parsed, allow_nil: true
                end
              end

              context 'in directmessage' do
                should 'parse command correctly' do
                  params = {
                      text: "#{@player1.team_tag} #{term} #{@player2.team_tag}",
                      user_id: 'CURRENTUSER',
                      team_id: 'SLACKTEAMID',
                      channel_name: 'directmessage'
                  }
                  expected = {
                      teams: [@player1.slack_user_id, @player2.slack_user_id],
                      players: [@player1.slack_user_id, @player2.slack_user_id],
                      team_size: 1,
                      action: :draw,
                      game_name: nil,
                      game_type: nil
                  }
                  parsed = CommandParser.new(params).parse
                  assert_equivalent expected, parsed, allow_nil: true
                end
              end

              context 'in privategroup' do
                should 'parse command correctly' do
                  params = {
                      text: "#{@player1.team_tag} #{term} #{@player2.team_tag}",
                      user_id: 'CURRENTUSER',
                      team_id: 'SLACKTEAMID',
                      channel_name: 'privategroupe'
                  }
                  expected = {
                      teams: [@player1.slack_user_id, @player2.slack_user_id],
                      players: [@player1.slack_user_id, @player2.slack_user_id],
                      team_size: 1,
                      action: :draw,
                      game_name: nil,
                      game_type: nil
                  }
                  parsed = CommandParser.new(params).parse
                  assert_equivalent expected, parsed, allow_nil: true
                end
              end
            end
          end

          context 'doubles' do
            context 'w/ specified game' do
              should 'parse command correctly' do
                params = {
                    text: "#{@doubles_player1.team_tag} #{term} #{@doubles_player2.team_tag} at #{@game_type.game_name}",
                    user_id: 'CURRENTUSER',
                    team_id: 'SLACKTEAMID',
                    channel_name: 'random'
                }
                expected = {
                    teams: [@doubles_player1.slack_user_id, @doubles_player2.slack_user_id],
                    players: @doubles_player1.slack_user_id.split('-') + @doubles_player2.slack_user_id.split('-'),
                    team_size: 2,
                    action: :draw,
                    game_name: @game_type.game_name,
                    game_type: @game_type
                }
                parsed = CommandParser.new(params).parse
                assert_equivalent expected, parsed
              end
            end

            context 'w/o specified game' do
              context 'in game channel' do
                should 'parse command correctly' do
                  params = {
                      text: "#{@doubles_player1.team_tag} #{term} #{@doubles_player2.team_tag}",
                      user_id: 'CURRENTUSER',
                      team_id: 'SLACKTEAMID',
                      channel_name: @game_type.game_name
                  }
                  expected = {
                      teams: [@doubles_player1.slack_user_id, @doubles_player2.slack_user_id],
                      players: @doubles_player1.slack_user_id.split('-') + @doubles_player2.slack_user_id.split('-'),
                      team_size: 2,
                      action: :draw,
                      game_name: @game_type.game_name,
                      game_type: @game_type
                  }
                  parsed = CommandParser.new(params).parse
                  assert_equivalent expected, parsed
                end
              end

              context 'in non-game channel' do
                should 'parse command correctly' do
                  params = {
                      text: "#{@doubles_player1.team_tag} #{term} #{@doubles_player2.team_tag}",
                      user_id: 'CURRENTUSER',
                      team_id: 'SLACKTEAMID',
                      channel_name: 'random'
                  }
                  expected = {
                      teams: [@doubles_player1.slack_user_id, @doubles_player2.slack_user_id],
                      players: @doubles_player1.slack_user_id.split('-') + @doubles_player2.slack_user_id.split('-'),
                      team_size: 2,
                      action: :draw,
                      game_name: nil,
                      game_type: nil
                  }
                  parsed = CommandParser.new(params).parse
                  assert_equivalent expected, parsed, allow_nil: true
                end
              end

              context 'in directmessage' do
                should 'parse command correctly' do
                  params = {
                      text: "#{@doubles_player1.team_tag} #{term} #{@doubles_player2.team_tag}",
                      user_id: 'CURRENTUSER',
                      team_id: 'SLACKTEAMID',
                      channel_name: 'directmessage'
                  }
                  expected = {
                      teams: [@doubles_player1.slack_user_id, @doubles_player2.slack_user_id],
                      players: @doubles_player1.slack_user_id.split('-') + @doubles_player2.slack_user_id.split('-'),
                      team_size: 2,
                      action: :draw,
                      game_name: nil,
                      game_type: nil
                  }
                  parsed = CommandParser.new(params).parse
                  assert_equivalent expected, parsed, allow_nil: true
                end
              end

              context 'in privategroup' do
                should 'parse command correctly' do
                  params = {
                      text: "#{@doubles_player1.team_tag} #{term} #{@doubles_player2.team_tag}",
                      user_id: 'CURRENTUSER',
                      team_id: 'SLACKTEAMID',
                      channel_name: 'privategroup'
                  }
                  expected = {
                      teams: [@doubles_player1.slack_user_id, @doubles_player2.slack_user_id],
                      players: @doubles_player1.slack_user_id.split('-') + @doubles_player2.slack_user_id.split('-'),
                      team_size: 2,
                      action: :draw,
                      game_name: nil,
                      game_type: nil
                  }
                  parsed = CommandParser.new(params).parse
                  assert_equivalent expected, parsed, allow_nil: true
                end
              end
            end
          end

          context 'uneven' do
            context 'w/ specified game' do
              should 'parse command correctly' do
                params = {
                    text: "#{@doubles_player1.team_tag} #{term} #{@doubles_player2.team_tag} at #{@game_type.game_name}",
                    user_id: 'CURRENTUSER',
                    team_id: 'SLACKTEAMID',
                    channel_name: 'random'
                }
                expected = {
                    teams: [@doubles_player1.slack_user_id, @doubles_player2.slack_user_id],
                    players: @doubles_player1.slack_user_id.split('-') + @doubles_player2.slack_user_id.split('-'),
                    team_size: 2,
                    action: :draw,
                    game_name: @game_type.game_name,
                    game_type: @game_type
                }
                parsed = CommandParser.new(params).parse
                assert_equivalent expected, parsed
              end
            end

            context 'w/o specified game' do
              context 'in game channel' do
                should 'parse command correctly' do
                  params = {
                      text: "#{@player1.team_tag} #{term} #{@doubles_player2.team_tag}",
                      user_id: 'CURRENTUSER',
                      team_id: 'SLACKTEAMID',
                      channel_name: @game_type.game_name
                  }
                  expected = {
                      teams: [@player1.slack_user_id, @doubles_player2.slack_user_id],
                      players: @player1.slack_user_id.split('-') + @doubles_player2.slack_user_id.split('-'),
                      team_size: :uneven,
                      action: :draw,
                      game_name: @game_type.game_name,
                      game_type: @game_type
                  }
                  parsed = CommandParser.new(params).parse
                  assert_equivalent expected, parsed
                end
              end

              context 'in non-game channel' do
                should 'parse command correctly' do
                  params = {
                      text: "#{@player1.team_tag} #{term} #{@doubles_player2.team_tag}",
                      user_id: 'CURRENTUSER',
                      team_id: 'SLACKTEAMID',
                      channel_name: 'random'
                  }
                  expected = {
                      teams: [@player1.slack_user_id, @doubles_player2.slack_user_id],
                      players: @player1.slack_user_id.split('-') + @doubles_player2.slack_user_id.split('-'),
                      team_size: :uneven,
                      action: :draw,
                      game_name: nil,
                      game_type: nil
                  }
                  parsed = CommandParser.new(params).parse
                  assert_equivalent expected, parsed, allow_nil: true
                end
              end

              context 'in directmessage' do
                should 'parse command correctly' do
                  params = {
                      text: "#{@player1.team_tag} #{term} #{@doubles_player2.team_tag}",
                      user_id: 'CURRENTUSER',
                      team_id: 'SLACKTEAMID',
                      channel_name: 'directmessage'
                  }
                  expected = {
                      teams: [@player1.slack_user_id, @doubles_player2.slack_user_id],
                      players: @player1.slack_user_id.split('-') + @doubles_player2.slack_user_id.split('-'),
                      team_size: :uneven,
                      action: :draw,
                      game_name: nil,
                      game_type: nil
                  }
                  parsed = CommandParser.new(params).parse
                  assert_equivalent expected, parsed, allow_nil: true
                end
              end

              context 'in privategroup' do
                should 'parse command correctly' do
                  params = {
                      text: "#{@player1.team_tag} #{term} #{@doubles_player2.team_tag}",
                      user_id: 'CURRENTUSER',
                      team_id: 'SLACKTEAMID',
                      channel_name: 'privategroup'
                  }
                  expected = {
                      teams: [@player1.slack_user_id, @doubles_player2.slack_user_id],
                      players: @player1.slack_user_id.split('-') + @doubles_player2.slack_user_id.split('-'),
                      team_size: :uneven,
                      action: :draw,
                      game_name: nil,
                      game_type: nil
                  }
                  parsed = CommandParser.new(params).parse
                  assert_equivalent expected, parsed, allow_nil: true
                end
              end
            end
          end
        end
      end
    end
  end
end