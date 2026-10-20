Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # Every page lives under its locale ; without one, the browser's language picks it
  root "locales#redirect"
  get ":page", to: "locales#redirect", page: /lab|download|support/, as: nil

  scope ":locale", locale: /en|fr/ do
    get "/", to: "pages#home", as: :home
    get "lab", to: "pages#lab", as: :lab
    get "download", to: "pages#download", as: :download
    get "support", to: "pages#support", as: :support
  end
end
