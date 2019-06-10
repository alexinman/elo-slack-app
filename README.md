# Elo Slack App

A simple slack app that you can use to add a `/elo` command for your Slack team. Once added, `/elo` allows your team members to log games against each other for different types of games (ex. pingpong, foosball, etc) and have this app automatically keep track of everyone's Elo rating for each of the games. Provides the functionality to view your Elo rating or even see the leaderboards.

Commands:
 * `/elo [@winner] defeated [@loser] at [game]` logs a game for each player with `@winner` as the winner and changes both players Elo ratings accordingly.
 * `/elo [@player1] tied [@player2] at [game]` logs a tie game for each player and changes both players Elo ratings accordingly.
 * `/elo leaderboard [game]` displays the leaderboard for the specified game.
 * `/elo rating` lists your Elo rating for all types of games you've participated in.
 * `/elo help` shows a helpful message.

## Contributing
Fork and make a PR
