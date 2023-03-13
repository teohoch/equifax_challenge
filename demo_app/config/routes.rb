Rails.application.routes.draw do
  resources :comments
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  root to: "home#index"

  # Defines the root path route ("/")
  # root "articles#index"
end
