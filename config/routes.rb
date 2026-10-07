Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  resources :documents, except: %i[new] do
    resources :shares, only: %i[create destroy]
  end
  resource :import, only: :create

  get "up" => "rails/health#show", as: :rails_health_check

  root "documents#index"
end
