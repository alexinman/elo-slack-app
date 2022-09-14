module EloExtensions
end

module Elo
  class Player
    def inspect
      "<Elo::Player rating:#{rating} games_played:#{games_played}>"
    end
  end

  class Game
    def inspect
      "<Elo::Game\n\tone:#{one.inspect}\n\ttwo:#{two.inspect}\n\tresult:#{result}\n>"
    end
  end
end