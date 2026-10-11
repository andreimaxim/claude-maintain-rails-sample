Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  resource :session, only: [:new, :create, :destroy]
  resource :account, only: [:edit, :update]

  resources :notebooks, only: [:index, :new, :create, :edit, :update] do
    resource :import_preview, only: :create
    resources :imports, only: [:new, :create, :show]
    resources :exports, only: [:index, :create] do
      resource :cancellation, only: :create, controller: "export_cancellations"
      resource :download, only: :show, controller: "export_downloads"
    end
  end

  # /journal is a bookmark alias for the canonical /notes list.
  get "/notes", "/journal", to: "notes#index"
  resources :notes, except: :index do
    resource :citation_enrichment, only: :create
    resource :reminder, only: :create
    resource :reminder_postponement, only: :create
  end
  resource :digest, only: :create

  root to: redirect("/notes")
end
