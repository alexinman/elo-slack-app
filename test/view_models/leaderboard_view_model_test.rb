require 'test_helper'

class LeaderboardViewModelTest < ActiveSupport::TestCase
  context 'LeaderboardViewModelTest' do
    setup do
      @game_type = FactoryBot.create(:game_type)
    end

    context '#leaderboard' do
      [0, 1, 5, 10, 20].each do |num_singles|
        context "num_singles:#{num_singles.inspect}" do
          setup do
            reset_ratings
            @singles = num_singles.times.map { FactoryBot.create(:player, :singles, :with_singles_user_id, game_type: @game_type, rating: rating) }.sort_by { |p| [p.rating, p.id] }.reverse
          end

          [0, 1, 5, 10, 20].each do |num_doubles|
            context "num_doubles:#{num_doubles.inspect}" do
              setup do
                reset_ratings
                @doubles = num_doubles.times.map { FactoryBot.create(:player, :doubles, :with_doubles_user_id, game_type: @game_type, rating: rating) }.sort_by { |p| [p.rating, p.id] }.reverse
              end

              should 'return appropriate results' do
                Timecop.freeze do
                  expected = []
                  if num_singles > 0
                    expected << {
                        text: text(@singles),
                        footer_icon: 'http://localhost:3000/images/baseline_person_black_18dp.png',
                        footer: 'Singles',
                        ts: Time.now.to_i
                    }
                  end
                  if num_doubles > 0
                    expected << {
                        text: text(@doubles),
                        footer_icon: 'http://localhost:3000/images/baseline_people_black_18dp.png',
                        footer: 'Doubles',
                        ts: Time.now.to_i
                    }
                  end
                  results = LeaderboardViewModel.leaderboard(slack_team_id: 'SLACKTEAMID', game_type_id: @game_type.id).as_json.with_indifferent_access
                  assert_equivalent({items: expected}, results)
                end
              end
            end
          end
        end
      end

      context 'single player' do
        setup do
          @player = FactoryBot.create(:player, :singles, :with_singles_user_id, game_type: @game_type, rating: 1000)
        end

        should 'return player rating' do
          Timecop.freeze do
            expected = [
                {
                    text: text([@player]),
                    footer_icon: 'http://localhost:3000/images/baseline_person_black_18dp.png',
                    footer: 'Singles',
                    ts: Time.now.to_i
                }
            ]
            results = LeaderboardViewModel.leaderboard(slack_team_id: 'SLACKTEAMID', game_type_id: @game_type.id).as_json.with_indifferent_access
            assert_equivalent({items: expected}, results)
          end
        end

        context 'for another slack team' do
          setup do
            @player.update_column(:slack_team_id, 'DIFFERENT')
          end

          should 'not return player' do
            results = LeaderboardViewModel.leaderboard(slack_team_id: 'SLACKTEAMID', game_type_id: @game_type.id).as_json.with_indifferent_access
            assert_equivalent({items: []}, results)
          end
        end

        context 'for another game type' do
          setup do
            game_type = FactoryBot.create(:game_type)
            @player.update_column(:game_type_id, game_type.id)
          end

          should 'not return player' do
            results = LeaderboardViewModel.leaderboard(slack_team_id: 'SLACKTEAMID', game_type_id: @game_type.id).as_json.with_indifferent_access
            assert_equivalent({items: []}, results)
          end
        end
      end
    end

    context '#surrounding_ranks' do
      setup do
        @player1 = FactoryBot.create(:player, :singles, :with_singles_user_id, game_type: @game_type, rating: 1000)#1
        @player2 = FactoryBot.create(:player, :singles, :with_singles_user_id, game_type: @game_type, rating: 999)#2
        @player3 = FactoryBot.create(:player, :singles, :with_singles_user_id, game_type: @game_type, rating: 998)#3
        @player4 = FactoryBot.create(:player, :singles, :with_singles_user_id, game_type: @game_type, rating: 998)#4
        @player5 = FactoryBot.create(:player, :singles, :with_singles_user_id, game_type: @game_type, rating: 998)#5
        @player6 = FactoryBot.create(:player, :singles, :with_singles_user_id, game_type: @game_type, rating: 998)#6
        @player7 = FactoryBot.create(:player, :singles, :with_singles_user_id, game_type: @game_type, rating: 998)#7
        @player8 = FactoryBot.create(:player, :singles, :with_singles_user_id, game_type: @game_type, rating: 997)#8
        @player9 = FactoryBot.create(:player, :singles, :with_singles_user_id, game_type: @game_type, rating: 996)#9
      end

      should 'return player rank and rating along with surrounding ranks for player1' do
        expected = {
            items: [
                item_summary(@player1, 1),
                item_summary(@player2, 2)
            ]
        }
        results = LeaderboardViewModel.surrounding_ranks(@player1).as_json.with_indifferent_access
        assert_equivalent expected, results
      end

      should 'return player rank and rating along with surrounding ranks for player2' do
        expected = {
            items: [
                item_summary(@player1, 1),
                item_summary(@player2, 2),
                item_summary(@player3, 3)
            ]
        }
        results = LeaderboardViewModel.surrounding_ranks(@player2).as_json.with_indifferent_access
        assert_equivalent expected, results
      end

      should 'return player rank and rating along with surrounding ranks for player3' do
        expected = {
            items: [
                item_summary(@player2, 2),
                item_summary(@player3, 3),
                item_summary(@player4, 3)
            ]
        }
        results = LeaderboardViewModel.surrounding_ranks(@player3).as_json.with_indifferent_access
        assert_equivalent expected, results
      end

      should 'return player rank and rating along with surrounding ranks for player4' do
        expected = {
            items: [
                item_summary(@player3, 3),
                item_summary(@player4, 3),
                item_summary(@player5, 3),
            ]
        }
        results = LeaderboardViewModel.surrounding_ranks(@player4).as_json.with_indifferent_access
        assert_equivalent expected, results
      end

      should 'return player rank and rating along with surrounding ranks for player5' do
        expected = {
            items: [
                item_summary(@player4, 3),
                item_summary(@player5, 3),
                item_summary(@player6, 3)
            ]
        }
        results = LeaderboardViewModel.surrounding_ranks(@player5).as_json.with_indifferent_access
        assert_equivalent expected, results
      end

      should 'return player rank and rating along with surrounding ranks for player6' do
        expected = {
            items: [
                item_summary(@player5, 3),
                item_summary(@player6, 3),
                item_summary(@player7, 3)
            ]
        }
        results = LeaderboardViewModel.surrounding_ranks(@player6).as_json.with_indifferent_access
        assert_equivalent expected, results
      end

      should 'return player rank and rating along with surrounding ranks for player7' do
        expected = {
            items: [
                item_summary(@player6, 3),
                item_summary(@player7, 3),
                item_summary(@player8, 4)
            ]
        }
        results = LeaderboardViewModel.surrounding_ranks(@player7).as_json.with_indifferent_access
        assert_equivalent expected, results
      end

      should 'return player rank and rating along with surrounding ranks for player8' do
        expected = {
            items: [
                item_summary(@player7, 3),
                item_summary(@player8, 4),
                item_summary(@player9, 5)
            ]
        }
        results = LeaderboardViewModel.surrounding_ranks(@player8).as_json.with_indifferent_access
        assert_equivalent expected, results
      end

      should 'return player rank and rating along with surrounding ranks for player9' do
        expected = {
            items: [
                item_summary(@player8, 4),
                item_summary(@player9, 5)
            ]
        }
        results = LeaderboardViewModel.surrounding_ranks(@player9).as_json.with_indifferent_access
        assert_equivalent expected, results
      end
    end
  end

  def text(players)
    rank = 0
    prev_rating = ratings.max + 1
    players.first(10).map do |p|
      rank += 1 unless p.rating == prev_rating
      prev_rating = p.rating
      item_summary(p, rank)
    end.join("\n")
  end

  def item_summary(player, rank)
    "#{rank}. #{player.team_tag} (#{player.rating})"
  end

  def reset_ratings
    @ratings = ratings
  end

  def rating
    @ratings.shift
  end

  def ratings
    [983, 1002, 983, 907, 1008, 1046, 1097, 1001, 1031, 1010, 926, 1093, 992, 957, 1086, 968, 1010, 1048, 1088, 912]
  end
end