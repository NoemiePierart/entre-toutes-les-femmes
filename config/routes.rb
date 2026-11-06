Rails.application.routes.draw do
  # No public sign-up: the only account is the admin's. Editing it stays possible.
  devise_for :users, skip: :registrations, controllers: { sessions: "users/sessions" }
  devise_scope :user do
    get "users/edit", to: "devise/registrations#edit", as: :edit_user_registration
    match "users", to: "devise/registrations#update", via: %i[patch put], as: :user_registration
  end
  get "admin", to: redirect("/users/sign_in"), as: :admin_login
  resources :newsletters, only: [ :index, :show ], path: "lettres"
  get "themes/qui-suis-je", to: redirect("/themes/mystere-feminin")
  resources :themes, only: [ :show ]
  resources :posts
  get "auteur", to: "pages#about", as: :about
  get "a-propos", to: redirect("/auteur")
  get "contact", to: "pages#contact", as: :contact
  get "mentions-legales", to: "pages#legal", as: :legal
  get "confidentialite", to: "pages#privacy", as: :privacy
  get "images", to: "pages#images", as: :images_index
  post "subscribe", to: "subscriptions#create", as: :subscribe
  post "webhooks/brevo", to: "webhooks#brevo", as: :brevo_webhook
  get "sitemap.xml", to: "sitemaps#index", defaults: { format: :xml }, as: :sitemap
  root to: "pages#home"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
