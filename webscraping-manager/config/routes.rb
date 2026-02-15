Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get '/test_protected', to: 'test#protected_route'
  root "home#index"
  resources :tasks, only: [:create, :index]
end
