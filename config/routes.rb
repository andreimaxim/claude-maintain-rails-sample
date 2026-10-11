Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  resource :session, only: [:new, :create, :destroy]

  resources :notebooks, only: [:index, :new, :create]

  # /journal is a bookmark alias for the canonical /notes list.
  get "/notes", "/journal", to: "notes#index"
  resources :notes, except: [:index, :show]

  root to: redirect("/notes")
end
