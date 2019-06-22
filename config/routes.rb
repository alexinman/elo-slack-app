Rails.application.routes.draw do
  post '/elo', :controller => 'elo', :action => 'elo'

  scope :path => 'api', :controller => 'player' do
    get '/players', :action => 'players'
  end

  scope :path => 'api', :controller => 'game' do
    get '/games', :action => 'games'
    get '/games/types', :action => 'types'
  end
end
