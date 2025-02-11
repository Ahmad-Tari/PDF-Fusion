Rails.application.routes.draw do
  root "home#index"
  post "upload_csv", to: "home#upload_csv"
  get "download_pdf", to: "home#download_pdf"
  get 'template', to: 'home#template'
  resources :documents, only: [:create, :destroy]

  get "up" => "rails/health#show", as: :rails_health_check
end