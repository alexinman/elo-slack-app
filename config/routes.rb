Rails.application.routes.draw do
  post '/elo', :controller => 'elo', :action => 'elo'
  get '/game/history', :controller => 'game', :action => 'history'
  get '/player/leaderboard', :controller => 'player', :action => 'leaderboard'
  get '/game/gametypes', :controller => 'game', :action => 'gametypes'
end
