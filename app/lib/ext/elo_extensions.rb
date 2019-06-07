module Elo
  class Player
    def inspect
      "<Elo::Player rating:#{rating} games_player:#{games_played}>"
    end
  end

  class Game
    def inspect
      "<Elo::Game\n\tone:#{one}\n\ttwo:#{two}\n\tresult:#{result}\n>"
    end
  end
end