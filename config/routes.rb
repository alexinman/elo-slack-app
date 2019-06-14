Rails.application.routes.draw do
  post '/elo', :controller => 'elo', :action => 'elo'
end
Rails.application.routes.draw do
  get '/history', :controller => 'webapi', :action => 'history'
end
Rails.application.routes.draw do
  get '/leaderboard', :controller => 'webapi', :action => 'leaderboard'
end
Rails.application.routes.draw do
  get '/gametypes', :controller => 'webapi', :action => 'gametypes'
end
