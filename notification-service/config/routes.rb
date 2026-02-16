Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  post '/update_progress', to: 'notifications#update_progress'

  mount ActionCable.server => '/cable'
end
