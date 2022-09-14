require 'test_helper'

class GameTypeViewModelTest < ActiveSupport::TestCase
  SORT_ORDERS = [:game_name, :created_at].freeze
  OPTIONAL_PARAMETERS = [].freeze

  context 'GameTypeViewModelTest' do
    setup_basic_view_model_tests(SORT_ORDERS, OPTIONAL_PARAMETERS)
  end

  def view_model
    GameTypeViewModel
  end

  def model
    GameType
  end
end