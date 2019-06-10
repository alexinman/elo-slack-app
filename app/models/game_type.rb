class GameType < ActiveRecord::Base
  has_many :players
end
