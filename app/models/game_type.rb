class GameType < ActiveRecord::Base
  has_many :players

  delegate :titleize, to: :game_type
end
